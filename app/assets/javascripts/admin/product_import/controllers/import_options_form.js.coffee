angular.module("ofn.admin").controller "ImportOptionsFormCtrl", ($scope, $rootScope, ProductImportService) ->

  $scope.initForm = () ->
    $scope.settings = {} if $scope.settings == undefined
    $scope.settings[$scope.supplierId] = {
      defaults:
        count_on_hand:
          mode: 'overwrite_all'
        on_hand:
          mode: 'overwrite_all'
        tax_category_id:
          mode: 'overwrite_all'
        shipping_category_id:
          mode: 'overwrite_all'
        available_on:
          mode: 'overwrite_all'
    }

  $scope.$watch 'settings', (updated) ->
    ProductImportService.updateSettings(updated)
  , true

  $scope.toggleResetAbsent = (id) ->
    resetAbsent = $scope.settings[id]['reset_all_absent']
    confirmed = confirm t('js.product_import.confirmation') if resetAbsent

    if confirmed or !resetAbsent
      ProductImportService.updateResetAbsent($scope.supplierId, $scope.reset_counts[$scope.supplierId], resetAbsent)

  $scope.resetTotal = ProductImportService.resetTotal

  $rootScope.$watch 'resetTotal', (newValue) ->
    $scope.resetTotal = newValue if newValue || newValue == 0
