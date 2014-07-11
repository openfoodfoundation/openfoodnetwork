Darkswarm.controller "ProductNodeCtrl", ($scope, $modal) ->
  $scope.enterprise = $scope.product.supplier # For the modal, so it's consistent
  $scope.hasVariants = $scope.product.variants.length > 0

  $scope.triggerProductModal = ->
    $modal.open(templateUrl: "product_modal.html", scope: $scope)

