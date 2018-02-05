angular.module("admin.orderCycles").filter "available", ($filter) ->
  return (orderCycles, selectedOrderCycles) ->
    return orderCycles unless selectedOrderCycles?.length > 0
    $filter('filter')(orderCycles, (orderCycle) ->
      (selectedOrderCycles.indexOf(orderCycle) == -1) &&
      (orderCycle.coordinator.id == selectedOrderCycles[0].coordinator.id)
    )
