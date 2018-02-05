angular.module("admin.orderCycles").controller "OrderCyclesCtrl", ($scope, $q, Columns, StatusMessage, RequestMonitor, OrderCycles, Enterprises, Schedules, Dereferencer) ->
  $scope.RequestMonitor = RequestMonitor
  $scope.columns = Columns.columns
  $scope.saveAll = -> OrderCycles.saveChanges($scope.order_cycles_form)
  $scope.ordersCloseAtLimit = -31 # days
  $scope.involvingFilter = 0
  $scope.scheduleFilter = 0

  compileData = ->
    for schedule in $scope.schedules
      Dereferencer.dereference(schedule.order_cycles, OrderCycles.byID)
    for orderCycle in $scope.orderCycles
      coordinator = Enterprises.byID[orderCycle.coordinator.id]
      orderCycle.coordinator = coordinator if coordinator?
      Dereferencer.dereference(orderCycle.producers, Enterprises.byID)
      Dereferencer.dereference(orderCycle.shops, Enterprises.byID)
      Dereferencer.dereference(orderCycle.schedules, Schedules.byID)
      orderCycle.involvedEnterpriseIDs = [orderCycle.coordinator.id]
      orderCycle.producerNames = orderCycle.producers.map((producer) -> orderCycle.involvedEnterpriseIDs.push(producer.id); producer.name).join(", ")
      orderCycle.shopNames = orderCycle.shops.map((shop) -> orderCycle.involvedEnterpriseIDs.push(shop.id); shop.name).join(", ")

  # NOTE: this is using the Enterprises service from the admin.enterprises module
  RequestMonitor.load ($scope.enterprises = Enterprises.index(action: "visible", ams_prefix: "basic")).$promise
  $scope.schedules = Schedules.index()
  $scope.orderCycles = OrderCycles.index(ams_prefix: "index", "q[orders_close_at_gt]": "#{daysFromToday($scope.ordersCloseAtLimit)}")
  RequestMonitor.load $q.all([$scope.enterprises.$promise, $scope.schedules.$promise, $scope.orderCycles.$promise]).then -> compileData()

  $scope.$watch 'order_cycles_form.$dirty', (newVal, oldVal) ->
    StatusMessage.display 'notice', "You have unsaved changes" if newVal

  $scope.showMore = (days) ->
    $scope.ordersCloseAtLimit -= days
    existingIDs = Object.keys(OrderCycles.byID)
    orderCycles = OrderCycles.index(ams_prefix: "index", "q[orders_close_at_gt]": "#{daysFromToday($scope.ordersCloseAtLimit)}", "q[id_not_in][]": existingIDs)
    orderCycles.$promise.then ->
      $scope.orderCycles.push(orderCycle) for orderCycle in orderCycles
      compileData()

daysFromToday = (days) ->
  now = new Date
  now.setHours(0)
  now.setMinutes(0)
  now.setSeconds(0)
  now.setDate( now.getDate() + days )
  now
