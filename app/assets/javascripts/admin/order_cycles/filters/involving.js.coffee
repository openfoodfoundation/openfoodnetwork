angular.module("admin.orderCycles").filter "involving", ($filter) ->
  return (orderCycles, enterpriseID) ->
    return orderCycles if enterpriseID == 0
    $filter('filter')(orderCycles, (orderCycle) ->
      enterpriseID in orderCycle.involvedEnterpriseIDs
    )
