angular.module('Darkswarm').controller "ProductNodeCtrl", ($scope, FilterSelectorsService) ->
  $scope.enterprise = $scope.product.producer # For the modal, so it's consistent
  $scope.productPropertySelectors = FilterSelectorsService.createSelectors()
