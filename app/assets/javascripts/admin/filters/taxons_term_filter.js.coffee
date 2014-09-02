angular.module("ofn.admin").filter "taxonsTermFilter", ->
  return (lineItems,selectedSupplier,selectedDistributor,selectedOrderCycle) ->
    filtered = []
    filtered.push lineItem for lineItem in lineItems when (angular.equals(selectedSupplier,"0") || lineItem.supplier.id == selectedSupplier) &&
      (angular.equals(selectedDistributor,"0") || lineItem.order.distributor.id == selectedDistributor) &&
      (angular.equals(selectedOrderCycle,"0") || lineItem.order.order_cycle.id == selectedOrderCycle)
    filtered