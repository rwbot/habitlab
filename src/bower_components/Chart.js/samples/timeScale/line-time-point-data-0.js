
		function randomScalingFactor() {
			return Math.round(Math.random() * 100 * (Math.random() > 0.5 ? -1 : 1));
		}

		function randomColorFactor() {
			return Math.round(Math.random() * 255);
		}

		function randomColor(opacity) {
			return 'rgba(' + randomColorFactor() + ',' + randomColorFactor() + ',' + randomColorFactor() + ',' + (opacity || '.3') + ')';
		}

		function newDate(days) {
			return moment().add(days, 'd').toDate();
		}
		
		function newDateString(days) {
			return moment().add(days, 'd').format();
		}

		var config = {
			type: 'line',
			data: {
				datasets: [{
					label: "Dataset with string point data",
					data: [{
						x: newDateString(0),
						y: randomScalingFactor()
					}, {
						x: newDateString(2),
						y: randomScalingFactor()
					}, {
						x: newDateString(4),
						y: randomScalingFactor()
					}, {
						x: newDateString(5),
						y: randomScalingFactor()
					}],
					fill: false
				}, {
					label: "Dataset with date object point data",
					data: [{
						x: newDate(0),
						y: randomScalingFactor()
					}, {
						x: newDate(2),
						y: randomScalingFactor()
					}, {
						x: newDate(4),
						y: randomScalingFactor()
					}, {
						x: newDate(5),
						y: randomScalingFactor()
					}],
					fill: false
				}]
			},
			options: {
				responsive: true,
                title:{
                    display:true,
                    text:"Chart.js Time Point Data"
                },
				scales: {
					xAxes: [{
						type: "time",
						display: true,
						scaleLabel: {
							display: true,
							labelString: 'Date'
						}
					}],
					yAxes: [{
						display: true,
						scaleLabel: {
							display: true,
							labelString: 'value'
						}
					}]
				}
			}
		};

		$.each(config.data.datasets, function(i, dataset) {
			dataset.borderColor = randomColor(0.4);
			dataset.backgroundColor = randomColor(0.5);
			dataset.pointBorderColor = randomColor(0.7);
			dataset.pointBackgroundColor = randomColor(0.5);
			dataset.pointBorderWidth = 1;
		});

		window.onload = function() {
			var ctx = document.getElementById("canvas").getContext("2d");
			window.myLine = new Chart(ctx, config);

		};

		$('#randomizeData').click(function() {
			$.each(config.data.datasets, function(i, dataset) {
				$.each(dataset.data, function(j, dataObj) {
					dataObj.y = randomScalingFactor();
				});
			});

			window.myLine.update();
		});

		$('#addData').click(function() {
			if (config.data.datasets.length > 0) {
				var lastTime = myLine.scales['x-axis-0'].labelMoments[0].length ? myLine.scales['x-axis-0'].labelMoments[0][myLine.scales['x-axis-0'].labelMoments[0].length - 1] : moment();
				var newTime = lastTime
					.clone()
					.add(1, 'day')
					.format('MM/DD/YYYY HH:mm');

				for (var index = 0; index < config.data.datasets.length; ++index) {
					config.data.datasets[index].data.push({
						x: newTime,
						y: randomScalingFactor()
					});
				}

				window.myLine.update();
			}
		});

		$('#removeData').click(function() {
			config.data.datasets.forEach(function(dataset, datasetIndex) {
				dataset.data.pop();
			});

			window.myLine.update();
		});
	