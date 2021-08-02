angular.module('Darkswarm').directive "priceBreakdown", ($tooltip)->
  # We use the $tooltip service from Angular foundation to give us boilerplate
  # Subsequently we patch the scope, template and restrictions
  tooltip = $tooltip 'priceBreakdown', 'priceBreakdown', 'click'
  tooltip.scope =
    variant: "="
  tooltip.templateUrl = "price_breakdown_button.html"
  tooltip.replace = true
  tooltip.restrict = 'E'
  tooltip

# This is automatically referenced via naming convention in $tooltip
angular.module('Darkswarm').directive 'priceBreakdownPopup', ->
  restrict: 'EA'
  replace: true
  templateUrl: 'price_breakdown.html'
  scope: false
