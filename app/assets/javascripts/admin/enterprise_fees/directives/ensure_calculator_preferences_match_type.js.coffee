angular.module("admin.enterpriseFees").directive 'spreeEnsureCalculatorPreferencesMatchType', ->
  # Hide calculator preference fields when calculator type changed
  # Fixes 'Enterprise fee is not found' error when changing calculator type
  # See spree/core/app/assets/javascripts/admin/calculator.js
  # Note: For some reason, DOM --> model bindings aren't working here, so
  # we use element.val() instead of querying the model itself.
  (scope, element, attrs) ->
    scope.$watch ((scope) ->
      #return scope.enterprise_fee.calculator_type;
      element.val()
    ), (value) ->
      settings = element.parent().parent().find('div.calculator-settings')
      # scope.enterprise_fee.calculator_type == scope.enterprise_fee.orig_calculator_type
      if element.val() == scope.enterprise_fee.orig_calculator_type
        settings.show()
        settings.find('input').prop 'disabled', false
      else
        settings.hide()
        settings.find('input').prop 'disabled', true
      return
    return
