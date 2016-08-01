angular.module('admin.orderCycles').controller 'AdminAdvancedOrderCyclesCtrl', ($rootScope, $scope, $filter, $location, $window, $q, $timeout, $http, OrderCycles, Enterprise, EnterpriseFee, StatusMessage, RequestMonitor) ->
  current_order_cycle_id = $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]
  $scope.order_cycles = OrderCycles.index(includeBlank: true, ams_prefix: "basic")
  $scope.StatusMessage = StatusMessage

  $scope.copyProducts = ->
    StatusMessage.display 'progress', t('admin.order_cycles.edit.copying_products')
    if angular.isDefined($scope.order_cycle_to_copy)
      $http
        method: "POST"
        url: "/admin/order_cycles/" + current_order_cycle_id + "/copy_settings"
        data: { oc_to_copy: $scope.order_cycle_to_copy.id }
      .success (response) ->
        $rootScope.$emit('refreshOC', response.id)
        $timeout -> t('admin.order_cycles.edit.products_copied')
      .error (data, status) ->
        $timeout -> StatusMessage.display 'failure', t('admin.order_cycles.edit.failed_to_copy_products') + ': ' + status
    else
      StatusMessage.display 'alert', t('admin.order_cycles.edit.select_an_order_cycle_first')
