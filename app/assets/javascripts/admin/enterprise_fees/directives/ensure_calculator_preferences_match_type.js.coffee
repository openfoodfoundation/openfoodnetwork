angular.module("admin.enterpriseFees").directive 'spreeEnsureCalculatorPreferencesMatchType', ->
  # Hide calculator preference fields when calculator type changed
  # Fixes 'Enterprise fee is not found' error when changing calculator type
  # See spree/core/app/assets/javascripts/admin/calculator.js
  (scope, element, attrs) ->
    orig_calculator_type = scope.enterprise_fee.calculator_type

    scope.$watch "enterprise_fee.calculator_type", (value) ->
      settings = element.parent().parent().find('div.calculator-settings')
      if value == orig_calculator_type
        settings.show()
        settings.find('input').prop 'disabled', false
      else
        settings.hide()
        settings.find('input').prop 'disabled', true
      return
    return
