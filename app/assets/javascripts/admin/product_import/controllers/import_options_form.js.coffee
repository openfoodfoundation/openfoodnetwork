angular.module("admin.productImport").controller "ImportOptionsFormCtrl", ($scope, $rootScope, ProductImportService) ->

  $scope.initForm = () ->
    $scope.settings = {} if $scope.settings == undefined
    $scope.settings[$scope.supplierId] = {
      import_into: 'product_list'
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
    $scope.import_into = 'product_list'

  $scope.updateImportInto = () ->
    $scope.import_into = $scope.settings[$scope.supplierId]['import_into']

  $scope.$watch 'settings', (updated) ->
    ProductImportService.updateSettings(updated)
  , true

  $scope.toggleResetAbsent = (id) ->
    checked = $scope.settings[id]['reset_all_absent']
    confirmed = confirm t('js.product_import.confirmation') if checked

    if confirmed or !checked
      ProductImportService.updateResetAbsent($scope.supplierId, $scope.reset_counts[$scope.supplierId], checked)
    else
      $scope.settings[id]['reset_all_absent'] = false

  $scope.resetTotal = ProductImportService.resetTotal

  $rootScope.$watch 'resetTotal', (newValue) ->
    $scope.resetTotal = newValue if newValue || newValue == 0
