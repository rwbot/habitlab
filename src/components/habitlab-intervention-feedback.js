const {
  log_feedback
} = require('libs_frontend/intervention_log_utils')

Polymer({
  is: 'habitlab-intervention-feedback',
  properties: {
    time_spent_printable: {
      type: String,
      computed: 'compute_time_spent_printable(seconds_spent)',
    },
    intervention_info: {
      type: Object,
    },
    goal_info: {
      type: Object,
    },
    seconds_spent: {
      type: Number,
      value: 0,
    },
    isdemo: {
      type: Boolean,
      observer: 'isdemo_changed',
    },
    intervention_name: {
      type: String,
      //value: (intervention != null) ? intervention.displayname : ''
      computed: 'compute_intervention_name(intervention_info)'
    },
    intervention_description: {
      type: String,
      //value: (intervention != null) ? intervention.description : '',
      computed: 'compute_intervention_description(intervention_info)'
    },
  },
  compute_intervention_name: function(intervention_info) {
    if (intervention_info != null) {
      return intervention_info.displayname
    }
    return ''
  },
  compute_intervention_description: function(intervention_info) {
    if (intervention_info != null) {
      return intervention_info.description
    }
    return ''
  },
  compute_time_spent_printable: function(seconds_spent) {
    return Math.round(seconds_spent / 60).toString() + ' minutes'
  },
  isdemo_changed: function() {
    if (this.isdemo) {
      this.show();
    }
  },
  too_intense_clicked: async function() {
    log_feedback({
      feedback_type: 'intensity',
      intensity: 'too_intense'
    })
    this.close()
  },
  not_intense_clicked: async function() {
    log_feedback({
      feedback_type: 'intensity',
      intensity: 'not_intense'
    })
    this.close()
  },
  just_right_clicked: async function() {
    log_feedback({
      feedback_type: 'intensity',
      intensity: 'just_right'
    })
    this.close()
  },
  get_intervention_icon_url: function() {
    let url_path
    if (intervention.generic_intervention != null)
      url_path = 'interventions/'+ intervention.generic_intervention + '/icon.svg'
    else {
      if (intervention.custom == true) {
        url_path = 'icons/custom_intervention_icon.svg'
      } else {
        url_path = 'interventions/'+ intervention.name + '/icon.svg'
      }
    }
    return (chrome.extension.getURL(url_path)).toString()
  },
  close: function() {
    this.$$('#sample_toast').hide()
  },
  show: function() {
    if (this.intervention_info == null) {
      this.intervention_info = require('libs_common/intervention_info').get_intervention();
    }
    this.$$('#sample_toast').show()
  },
})
