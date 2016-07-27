angular.module("admin.orderCycles").directive 'orderCyclesSelector', (OrderCycles, Schedules) ->
  restrict: 'C'
  templateUrl: 'admin/order_cycles_selector.html'
  link: (scope, element, attr) ->
    scope.selectedOrderCycles = (orderCycle for id, orderCycle of OrderCycles.orderCyclesByID when orderCycle.id in scope.schedule.order_cycle_ids)
    scope.availableOrderCycles = (orderCycle for id, orderCycle of OrderCycles.orderCyclesByID when orderCycle.id not in scope.schedule.order_cycle_ids)

    element.find('#available-order-cycles .order-cycles').sortable
      connectWith: '#selected-order-cycles .order-cycles'

    element.find('#selected-order-cycles .order-cycles').sortable
      connectWith: '#available-order-cycles .order-cycles'
      receive: (event, ui) ->
        scope.schedule.order_cycle_ids = $('#selected-order-cycles .order-cycles').children('.order-cycle').map((i, element) -> $(element).scope().orderCycle.id).get()
      remove: (event, ui) ->
        scope.schedule.order_cycle_ids = $('#selected-order-cycles .order-cycles').children('.order-cycle').map((i, element) -> $(element).scope().orderCycle.id).get()
