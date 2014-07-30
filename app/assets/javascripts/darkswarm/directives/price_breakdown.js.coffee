Darkswarm.directive "priceBreakdown", ($tooltip)->
  tooltip = $tooltip 'priceBreakdown', 'priceBreakdown', 'click' 
  tooltip.scope = 
    variant: "="
  tooltip

Darkswarm.directive 'priceBreakdownPopup', ->
  restrict: 'EA'
  replace: true
  templateUrl: 'price_breakdown.html'
  scope: false

  link: (scope, elem, attrs) ->
    scope.expanded = false unless scope.expanded?
