angular.module("admin.productImport").controller "ImportOptionsFormCtrl", ($scope, $rootScope, ProductImportService) ->

  $scope.initForm = () ->
    $scope.settings = {} if $scope.settings == undefined
    $scope.settings = {
      import_into: 'product_list',
      reset_all_absent: false
    }
    $scope.import_into = 'product_list'

  $scope.$watch 'settings', (updated) ->
    ProductImportService.updateSettings(updated)
  , true

  $scope.toggleResetAbsent = ->
    checked = $scope.settings['reset_all_absent']
    confirmed = confirm t('js.product_import.confirmation') if checked

    if confirmed or !checked
      ProductImportService.updateResetAbsent($scope.enterpriseId, $scope.reset_counts[$scope.enterpriseId], checked)
    else
      $scope.settings['reset_all_absent'] = false

  $scope.resetTotal = ProductImportService.resetTotal

  $rootScope.$watch 'resetTotal', (newValue) ->
    $scope.resetTotal = newValue if newValue || newValue == 0
