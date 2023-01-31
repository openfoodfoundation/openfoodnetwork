angular.module('admin.orderCycles')
  .controller 'AdminOrderCycleBasicCtrl', ($scope, $filter, $window, OrderCycle, Enterprise, EnterpriseFee, Schedules, RequestMonitor, ocInstance, StatusMessage) ->
    $scope.StatusMessage = StatusMessage
    $scope.OrderCycle = OrderCycle

    $scope.$watch 'order_cycle_form.$dirty', (newValue) ->
      StatusMessage.display 'notice', t("admin.unsaved_changes") if newValue

    $scope.$watch 'order_cycle_form.$valid', (isValid) ->
      StatusMessage.setValidation(isValid)

    $scope.loaded = ->
      Enterprise.loaded && EnterpriseFee.loaded && OrderCycle.loaded && !RequestMonitor.loading

    $scope.enterpriseFeesForEnterprise = (enterprise_id) ->
      EnterpriseFee.forEnterprise(parseInt(enterprise_id))

    $scope.cancel = (destination) ->
      $window.location = destination

    # Used in panels/exchange_products_supplied.html
    $scope.suppliedVariants = (enterprise_id) ->
      Enterprise.suppliedVariants(enterprise_id)

    # Used in panels/exchange_products_supplied.html and panels/exchange_products_distributed.html
    $scope.setExchangeVariants = (exchange, variants, selected) ->
      OrderCycle.setExchangeVariants(exchange, variants, selected)

    # The following methods are specific to the general settings pages:
    #   - simple create, simple edit and general settings pages

    $scope.schedules = Schedules.index({enterprise_id: ocInstance.coordinator_id})

    $scope.addCoordinatorFee = ($event) ->
      $event.preventDefault()
      OrderCycle.addCoordinatorFee()

    $scope.removeCoordinatorFee = ($event, index) ->
      $event.preventDefault()
      OrderCycle.removeCoordinatorFee(index)
      $scope.order_cycle_form.$dirty = true
