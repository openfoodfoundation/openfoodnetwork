angular.module('Darkswarm').controller "ProductNodeCtrl", ($scope, $modal, FilterSelectorsService) ->
  $scope.enterprise = $scope.product.supplier # For the modal, so it's consistent
  $scope.productPropertySelectors = FilterSelectorsService.createSelectors()

  $scope.triggerProductModal = ->
    $modal.open(templateUrl: "product_modal.html", scope: $scope)
