angular.module('Darkswarm').controller "ProductNodeCtrl", ($scope, FilterSelectorsService) ->
  $scope.enterprise = $scope.product.supplier # For the modal, so it's consistent
  $scope.productPropertySelectors = FilterSelectorsService.createSelectors()
