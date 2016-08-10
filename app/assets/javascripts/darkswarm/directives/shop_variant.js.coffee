Darkswarm.directive "shopVariant", ->
  restrict: 'E'
  replace: true
  templateUrl: 'shop_variant.html'
  scope:
    variant: '='
  controller: ($scope, Cart) ->
    $scope.$watchGroup ['variant.line_item.quantity', 'variant.line_item.max_quantity'], ->
      Cart.adjust($scope.variant.line_item)
