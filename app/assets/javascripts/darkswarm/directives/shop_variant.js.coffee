Darkswarm.directive "shopVariant", ->
  restrict: 'E'
  replace: true
  templateUrl: 'shop_variant.html'
  scope:
    variant: '='
  controller: ($scope, Cart) ->
    $scope.$watchGroup [
      'variant.line_item.quantity',
      'variant.line_item.max_quantity'
    ], (new_value, old_value) ->
      return if old_value[0] == null && new_value[0] == null
      Cart.adjust($scope.variant.line_item)
