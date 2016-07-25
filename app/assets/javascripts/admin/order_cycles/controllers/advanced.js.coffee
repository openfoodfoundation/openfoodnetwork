angular.module('admin.orderCycles').controller 'AdminAdvancedOrderCyclesCtrl', ($rootScope, $scope, $filter, $location, $window, $q, $timeout, $http, OrderCycles, Enterprise, EnterpriseFee, StatusMessage, RequestMonitor) ->
  current_order_cycle_id = $location.absUrl().match(/\/admin\/order_cycles\/(\d+)/)[1]
  $scope.order_cycles = OrderCycles.index(includeBlank: true, ams_prefix: "basic")
  $scope.StatusMessage = StatusMessage

  $scope.copyProducts = ->
    if angular.isDefined($scope.order_cycle_to_copy)
      $http
        method: "POST"
        url: "/admin/order_cycles/" + current_order_cycle_id + "/copy_settings"
        data: { oc_to_copy: $scope.order_cycle_to_copy.id }
      .success (response) ->
        $rootScope.$emit('refreshOC', response.id)
        $timeout -> StatusMessage.display 'progress', 'Copying products...'
      .error (data, status) ->
        $timeout -> StatusMessage.display 'failure', 'Failed to copy products'
    else
      StatusMessage.display 'alert', 'Select an order cycle first.'
