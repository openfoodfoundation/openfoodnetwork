Darkswarm.controller "ProductNodeCtrl", ($scope, $modal) ->
  $scope.enterprise = $scope.product.supplier # For the modal, so it's consistent

  $scope.triggerProductModal = ->
    $modal.open(templateUrl: "product_modal.html", scope: $scope)

