angular.module("admin.reports").factory 'OrdersAndFulfillmentsReport', (uiGridGroupingConstants) ->
  new class OrdersAndFulfillmentsReport

    gridOptions: ->
      enableSorting: true
      enableFiltering: true
      columnDefs: [
        { field: 'id',                displayName: 'ID',                width: '10%', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.number',      displayName: 'Order',             width: '20%', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 1 } }
        { field: 'order.customer',    displayName: 'Customer',          width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, sort: { priority: 0, direction: 'asc' }, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerFinalizer }
        { field: 'order.email',       displayName: 'Email',             width: '20%', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        # { field: 'producer.name',   displayName: 'Producer',          width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.name',      displayName: 'Product',           width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @productFinalizer }
        { field: 'full_name',         displayName: 'Variant',           width: '25%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'quantity',          displayName: 'Qty',               width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'price',             displayName: 'Items ($)',         width: '15%', cellFilter: "currency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'price_with_fees',   displayName: 'Items + Fees ($)',  width: '15%', cellFilter: "currency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
      ]

    basicFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.value

    customerFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.customer

    productFinalizer: (aggregation) ->
      aggregation.rendered = "TOTAL"

    sumAggregator: (aggregation, fieldValue, numValue, row) ->
      aggregation.value = 0 unless aggregation.sum?
      aggregation.value += numValue

    orderAggregator: (aggregation, fieldValue, numValue, row) ->
      return if aggregation.order == row.entity.order
      if aggregation.order?
        aggregation.order = { }
      else
        aggregation.order = row.entity.order

    priceFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.display_total
