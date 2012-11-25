function AdminEnterpriseFeesCtrl($scope, $http) {
  $http.get('/admin/enterprise_fees.json').success(function(data) {
    $scope.enterprise_fees = data;

    // TODO: Angular 1.1.0 will have a means to reset a form to its pristine state, which
    //       would avoid the need to save off original calculator types for comparison.
    for(i in $scope.enterprise_fees) {
      $scope.enterprise_fees[i].orig_calculator_type = $scope.enterprise_fees[i].calculator_type;
    }
  });
}


angular.module('enterprise_fees', [])
  .directive('ngBindHtmlUnsafeCompiled', function($compile) {
    return function(scope, element, attrs) {
      scope.$watch(attrs.ngBindHtmlUnsafeCompiled, function(value) {
	element.html($compile(value)(scope));
      });
    }
  })
  .directive('spreeDeleteResource', function() {
    return function(scope, element, attrs) {
      if(scope.enterprise_fee.id) {
	var url = "/admin/enterprise_fees/" + scope.enterprise_fee.id
	var html = '<a href="'+url+'" class="delete-resource" data-confirm="Are you sure?"><img alt="Delete" src="/assets/admin/icons/delete.png" /> Delete</a>';
	element.append(html);
      }
    }
  })
  .directive('spreeEnsureCalculatorPreferencesMatchType', function() {
    // Hide calculator preference fields when calculator type changed
    // Fixes 'Enterprise fee is not found' error when changing calculator type
    // See spree/core/app/assets/javascripts/admin/calculator.js

    // Note: For some reason, DOM --> model bindings aren't working here, so
    // we use element.val() instead of querying the model itself.

    return function(scope, element, attrs) {
      scope.$watch(function(scope) {
	//return scope.enterprise_fee.calculator_type;
	return element.val();
      }, function(value) {
	var settings = element.parent().parent().find("div.calculator-settings");

	// scope.enterprise_fee.calculator_type == scope.enterprise_fee.orig_calculator_type
	if(element.val() == scope.enterprise_fee.orig_calculator_type) {
	  settings.show();
	  settings.find("input").prop("disabled", false);
	} else {
	  settings.hide();
	  settings.find("input").prop("disabled", true);
	}
      });
    }
  });
