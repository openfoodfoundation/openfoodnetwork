angular.module('admin.orderCycles')
  .controller 'AdminOrderCycleBasicCtrl', ($scope, $filter, $window, OrderCycle, Enterprise, EnterpriseFee, Schedules, RequestMonitor, ocInstance, StatusMessage) ->
    $scope.StatusMessage = StatusMessage
    $scope.OrderCycle = OrderCycle
    $scope.schedules = Schedules.index({enterprise_id: ocInstance.coordinator_id})

    $scope.$watch 'order_cycle_form.$dirty', (newValue) ->
      StatusMessage.display 'notice', t("admin.unsaved_changes") if newValue

    $scope.$watch 'order_cycle_form.$valid', (isValid) ->
      StatusMessage.setValidation(isValid)

    $scope.loaded = ->
      Enterprise.loaded && EnterpriseFee.loaded && OrderCycle.loaded && !RequestMonitor.loading

    $scope.suppliedVariants = (enterprise_id) ->
      Enterprise.suppliedVariants(enterprise_id)

    $scope.setExchangeVariants = (exchange, variants, selected) ->
      OrderCycle.setExchangeVariants(exchange, variants, selected)

    $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
      EnterpriseFee.forEnterprise(parseInt(enterprise_id))

    $scope.addCoordinatorFee = ($event) ->
      $event.preventDefault()
      OrderCycle.addCoordinatorFee()

    $scope.removeCoordinatorFee = ($event, index) ->
      $event.preventDefault()
      OrderCycle.removeCoordinatorFee(index)

    $scope.cancel = (destination) ->
      $window.location = destination
