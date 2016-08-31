angular.module("admin.lineItems").filter "selectFilter", (blankOption, RequestMonitor) ->
    return (lineItems,selectedSupplier,selectedDistributor,selectedOrderCycle) ->
      filtered = []
      unless RequestMonitor.loading
        filtered.push lineItem for lineItem in lineItems when (angular.equals(selectedSupplier,0) || lineItem.supplier.id == selectedSupplier) &&
          (angular.equals(selectedDistributor,0) || lineItem.order.distributor.id == selectedDistributor) &&
          (angular.equals(selectedOrderCycle,0) || lineItem.order.order_cycle.id == selectedOrderCycle)
      filtered
