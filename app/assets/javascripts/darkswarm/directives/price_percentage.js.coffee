Darkswarm.directive "pricePercentage", ->
  restrict: 'E'
  replace: true
  templateUrl: 'price_percentage.html'
  scope:
    percentage: '='

  link: (scope, elem, attrs) ->
    elem.find(".meter").css
      width: "#{scope.percentage}%"
