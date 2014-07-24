Darkswarm.directive "priceBreakdown", ($tooltip)->
  tooltip = $tooltip 'priceBreakdown', 'priceBreakdown', 'click' 
  tooltip.scope = 
    variant: "="
  tooltip

Darkswarm.directive 'priceBreakdownPopup', ()->
  restrict: 'EA'
  replace: true
  templateUrl: 'price_breakdown.html'
  scope: true
  #link: (scope, elem, attrs)->
    #angular.element($window).bind 'click', ->
        #scope.tt_isOpen = false
        #elem.remove()
