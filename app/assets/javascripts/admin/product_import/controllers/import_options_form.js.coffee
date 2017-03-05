angular.module("ofn.admin").controller "ImportOptionsFormCtrl", ($scope, $timeout, $rootScope, ProductImportService) ->

  $scope.toggleResetAbsent = () ->
    ProductImportService.updateResetAbsent($scope.supplierId, $scope.nonUpdated, $scope.resetAbsent)

  $scope.resetCount = ProductImportService.resetCount

  $rootScope.$watch 'resetCount', (newValue) ->
    $scope.resetCount = newValue if newValue || newValue == 0
