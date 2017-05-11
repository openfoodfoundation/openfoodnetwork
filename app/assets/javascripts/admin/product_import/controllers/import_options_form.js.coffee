angular.module("ofn.admin").controller "ImportOptionsFormCtrl", ($scope, $rootScope, ProductImportService) ->

  $scope.toggleResetAbsent = () ->
    confirmed = confirm t('js.product_import.confirmation') if $scope.resetAbsent

    if confirmed or !$scope.resetAbsent
      ProductImportService.updateResetAbsent($scope.supplierId, $scope.resetCount, $scope.resetAbsent)
    else
      $scope.resetAbsent = false

  $scope.resetTotal = ProductImportService.resetTotal

  $rootScope.$watch 'resetTotal', (newValue) ->
    $scope.resetTotal = newValue if newValue || newValue == 0
