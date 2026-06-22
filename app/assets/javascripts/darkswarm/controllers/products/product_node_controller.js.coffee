angular.module('Darkswarm').controller "ProductNodeCtrl", ($scope, FilterSelectorsService) ->
  $scope.enterprise = $scope.product.enterprise # For the modal, so it's consistent
  $scope.productPropertySelectors = FilterSelectorsService.createSelectors()
