angular.module("admin.orderCycles").filter "schedule", ($filter) ->
  return (orderCycles, scheduleID) ->
    return orderCycles if scheduleID == 0
    $filter('filter')(orderCycles, (orderCycle) ->
      scheduleID in orderCycle.schedules.map (oc) -> oc.id
    )
