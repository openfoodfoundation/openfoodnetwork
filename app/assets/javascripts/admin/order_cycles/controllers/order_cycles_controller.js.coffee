angular.module("admin.orderCycles").controller "OrderCyclesCtrl", ($scope, $q, StatusMessage, RequestMonitor, OrderCycles, Enterprises) ->
  $scope.RequestMonitor = RequestMonitor
  $scope.saveAll = -> OrderCycles.saveChanges($scope.order_cycles_form)
  $scope.ordersCloseAtLimit = -31 # days

  compileDataFor = (orderCycles) ->
    for orderCycle in orderCycles
      OrderCycles.linkToEnterprises(orderCycle)
      orderCycle.producerNames = orderCycle.producers.map((producer) -> producer.name).join(", ")
      orderCycle.shopNames = orderCycle.shops.map((shop) -> shop.name).join(", ")

  # NOTE: this is using the Enterprises service from the admin.enterprises module
  RequestMonitor.load ($scope.enterprises = Enterprises.index(includeBlank: true, action: "visible", ams_prefix: "basic")).$promise
  RequestMonitor.load ($scope.orderCycles = OrderCycles.index(ams_prefix: "index", "q[orders_close_at_gt]": "#{daysFromToday($scope.ordersCloseAtLimit)}")).$promise
  RequestMonitor.load $q.all([$scope.enterprises.$promise, $scope.orderCycles.$promise]).then -> compileDataFor($scope.orderCycles)

  $scope.$watch 'order_cycles_form.$dirty', (newVal, oldVal) ->
    StatusMessage.display 'notice', "You have unsaved changes" if newVal

  $scope.showMore = (days) ->
    $scope.ordersCloseAtLimit -= days
    existingIDs = Object.keys(OrderCycles.orderCyclesByID)
    RequestMonitor.load (orderCycles = OrderCycles.index(ams_prefix: "index", "q[orders_close_at_gt]": "#{daysFromToday($scope.ordersCloseAtLimit)}", "q[id_not_in][]": existingIDs)).$promise
    orderCycles.$promise.then ->
      compileDataFor(orderCycles)
      $scope.orderCycles.push(orderCycle) for orderCycle in orderCycles

daysFromToday = (days) ->
  now = new Date
  now.setHours(0)
  now.setMinutes(0)
  now.setSeconds(0)
  now.setDate( now.getDate() + days )
  now
