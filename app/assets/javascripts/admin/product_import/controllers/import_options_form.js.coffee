angular.module("ofn.admin").controller "ImportOptionsFormCtrl", ($scope, $rootScope, ProductImportService) ->

  $scope.toggleResetAbsent = () ->
    confirmed = confirm 'This will set stock level to zero on all products for this \n' +
      'enterprise that are not present in the uploaded file.' if $scope.resetAbsent

    if confirmed or !$scope.resetAbsent
      ProductImportService.updateResetAbsent($scope.supplierId, $scope.resetCount, $scope.resetAbsent)
    else
      $scope.resetAbsent = false

  $scope.resetTotal = ProductImportService.resetTotal

  $rootScope.$watch 'resetTotal', (newValue) ->
    $scope.resetTotal = newValue if newValue || newValue == 0
