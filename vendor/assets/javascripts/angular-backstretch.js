angular.module('backstretch', []);
angular.module('backstretch')
	.directive('backstretch', function () {
		return {
			restrict: 'A',
			link: function (scope, element, attr) {
				element.backstretch(attr.backgroundUrl);
			}
		}
	});
