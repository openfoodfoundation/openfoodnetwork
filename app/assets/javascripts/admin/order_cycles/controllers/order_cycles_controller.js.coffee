angular.module("admin.orderCycles").controller "OrderCyclesCtrl", ($scope, $q, Columns, StatusMessage, RequestMonitor, OrderCycles, Enterprises, Schedules) ->
  $scope.RequestMonitor = RequestMonitor
  $scope.columns = Columns.columns
  $scope.saveAll = -> OrderCycles.saveChanges($scope.order_cycles_form)
  $scope.ordersCloseAtLimit = -31 # days
  $scope.involvingFilter = 0

  compileData = ->
    for schedule in $scope.schedules
      Schedules.linkToOrderCycles(schedule)
    for orderCycle in $scope.orderCycles
      OrderCycles.linkToEnterprises(orderCycle)
      OrderCycles.linkToSchedules(orderCycle)
      orderCycle.involvedEnterpriseIDs = [orderCycle.coordinator.id]
      orderCycle.producerNames = orderCycle.producers.map((producer) -> orderCycle.involvedEnterpriseIDs.push(producer.id); producer.name).join(", ")
      orderCycle.shopNames = orderCycle.shops.map((shop) -> orderCycle.involvedEnterpriseIDs.push(shop.id); shop.name).join(", ")

  # NOTE: this is using the Enterprises service from the admin.enterprises module
  RequestMonitor.load ($scope.enterprises = Enterprises.index(action: "visible", ams_prefix: "basic")).$promise
  $scope.schedules = Schedules.index()
  RequestMonitor.load ($scope.orderCycles = OrderCycles.index(ams_prefix: "index", "q[orders_close_at_gt]": "#{daysFromToday($scope.ordersCloseAtLimit)}")).$promise
  RequestMonitor.load $q.all([$scope.enterprises.$promise, $scope.schedules.$promise, $scope.orderCycles.$promise]).then -> compileData()

  $scope.$watch 'order_cycles_form.$dirty', (newVal, oldVal) ->
    StatusMessage.display 'notice', "You have unsaved changes" if newVal

  $scope.showMore = (days) ->
    $scope.ordersCloseAtLimit -= days
    existingIDs = Object.keys(OrderCycles.orderCyclesByID)
    RequestMonitor.load (orderCycles = OrderCycles.index(ams_prefix: "index", "q[orders_close_at_gt]": "#{daysFromToday($scope.ordersCloseAtLimit)}", "q[id_not_in][]": existingIDs)).$promise
    orderCycles.$promise.then ->
      compileData()
      $scope.orderCycles.push(orderCycle) for orderCycle in orderCycles

daysFromToday = (days) ->
  now = new Date
  now.setHours(0)
  now.setMinutes(0)
  now.setSeconds(0)
  now.setDate( now.getDate() + days )
  now
