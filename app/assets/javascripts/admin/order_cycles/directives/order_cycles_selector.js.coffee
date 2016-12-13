angular.module("admin.orderCycles").directive 'orderCyclesSelector', ($timeout, OrderCycles) ->
  restrict: 'C'
  templateUrl: 'admin/order_cycles_selector.html'
  link: (scope, element, attr) ->
    scope.orderCycles = OrderCycles.all.filter (oc) -> oc.viewing_as_coordinator

    $timeout ->
      scope.selections =
        available: scope.availableOrderCycles[0]
        selected: scope.selectedOrderCycles[0]

    scope.add = (orderCycle) ->
      orderCycle ?= scope.selections.available
      index = scope.availableOrderCycles.indexOf(orderCycle)
      if index > -1
        scope.selectedOrderCycles.push orderCycle
        scope.selections.available = scope.availableOrderCycles[index+1] || scope.availableOrderCycles[index-1]
        scope.selections.selected = orderCycle

    scope.remove = (orderCycle) ->
      orderCycle ?= scope.selections.selected
      index = scope.selectedOrderCycles.indexOf(orderCycle)
      if index > -1
        scope.selectedOrderCycles.splice(index, 1)
        scope.selections.selected = scope.selectedOrderCycles[index] || scope.selectedOrderCycles[index-1]
        scope.selections.available = orderCycle
