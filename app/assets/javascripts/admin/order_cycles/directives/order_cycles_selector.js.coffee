angular.module("admin.orderCycles").directive 'orderCyclesSelector', (OrderCycles, Schedules) ->
  restrict: 'C'
  templateUrl: 'admin/order_cycles_selector.html'
  link: (scope, element, attr) ->
    if scope.scheduleID?
      scope.selectedOrderCycles = Schedules.byID[scope.scheduleID].orderCycles
      scope.orderCycleIDs = scope.selectedOrderCycles.map (i, orderCycle) -> orderCycle.id
    else
      scope.selectedOrderCycles = []

    scope.availableOrderCycles = (orderCycle for id, orderCycle of OrderCycles.orderCyclesByID when orderCycle not in scope.selectedOrderCycles)


    element.find('#available-order-cycles .order-cycles').sortable
      connectWith: '#selected-order-cycles .order-cycles'

    element.find('#selected-order-cycles .order-cycles').sortable
      connectWith: '#available-order-cycles .order-cycles'
      receive: (event, ui) ->
        scope.orderCycleIDs = $('#selected-order-cycles .order-cycles').children('.order-cycle').map((i, element) -> $(element).scope().orderCycle.id).get()
      remove: (event, ui) ->
        scope.orderCycleIDs = $('#selected-order-cycles .order-cycles').children('.order-cycle').map((i, element) -> $(element).scope().orderCycle.id).get()
