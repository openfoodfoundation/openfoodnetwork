angular.module("ofn.admin").controller "ImportOptionsFormCtrl", ($scope, $timeout, $rootScope, ProductImportService) ->

  $scope.toggleResetAbsent = () ->
    confirmed = confirm 'This will set stock level to zero on all products for this \n' +
      'enterprise that are not present in the uploaded file.' if $scope.resetAbsent

    if confirmed or !$scope.resetAbsent
      ProductImportService.updateResetAbsent($scope.supplierId, $scope.nonUpdated, $scope.resetAbsent)
    else
      $scope.resetAbsent = false

  $scope.resetCount = ProductImportService.resetCount

  $rootScope.$watch 'resetCount', (newValue) ->
    $scope.resetCount = newValue if newValue || newValue == 0
