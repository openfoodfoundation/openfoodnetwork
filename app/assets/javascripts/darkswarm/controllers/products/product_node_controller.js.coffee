Darkswarm.controller "ProductNodeCtrl", ($scope) ->
  $scope.price = ->
    if $scope.product.variants.length > 0
      prices = (v.price for v in $scope.product.variants)
      Math.min.apply(null, prices)
    else
      $scope.product.price

  $scope.hasVariants = $scope.product.variants.length > 0
