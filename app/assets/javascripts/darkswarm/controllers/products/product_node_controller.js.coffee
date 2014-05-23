Darkswarm.controller "ProductNodeCtrl", ($scope, $sce) ->

  $scope.price = ->
    if $scope.product.variants.length > 0
      prices = (v.price for v in $scope.product.variants)
      Math.min.apply(null, prices)
    else
      $scope.product.price

  $scope.producer = $scope.product.supplier
  $scope.producer.twitterific = true
  $scope.hasVariants = $scope.product.variants.length > 0

Darkswarm.filter "unsafe", ($sce) ->
  (val) ->
    $sce.trustAsHtml val

