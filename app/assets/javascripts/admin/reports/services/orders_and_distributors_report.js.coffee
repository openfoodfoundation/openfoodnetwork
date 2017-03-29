angular.module("admin.reports").factory 'OrdersAndDistributorsReport', (uiGridGroupingConstants) ->
  new class OrdersAndDistributorsReport

    gridOptions: ->
      enableSorting: true
      enableFiltering: true
      columnDefs: [
        { field: 'order.created_at',            displayName: 'Order date',            width: '15%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.id',                    displayName: 'Order ID',              width: '8%', visible: true, groupingShowAggregationMenu: true, groupingShowGroupingMenu: true, grouping: { groupPriority: 1 } }
        { field: 'order.customer',              displayName: 'Customer name',         width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerFinalizer }
        { field: 'order.email',                 displayName: 'Email',                 width: '15%', visible: true, groupingShowAggregationMenu: true, groupingShowGroupingMenu: truetreeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerEmailFinalizer }
        { field: 'order.phone',                 displayName: 'Phone',                 width: '10%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.city',                  displayName: 'City',                  width: '10%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.sku',                 displayName: 'SKU',                   width: '5%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.name',                displayName: 'Item name',             width: '10%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'full_name',                   displayName: 'Variant',               width: '10%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'quantity',                    displayName: 'Qty',                   width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'max_quantity',                displayName: 'Max Qty',               width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'cost',                        displayName: 'Cost',                  width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'distribution_fee',            displayName: 'Shipping Cost',         width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.payment_method',        displayName: 'Payment method',        width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.distributor.name',      displayName: 'Distributor',           width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.distributor.address',   displayName: 'Distributor address',   width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.distributor.city',      displayName: 'Distributor city',      width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.distributor.postcode',  displayName: 'Distributor postcode',  width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.special_instructions ', displayName: 'Shipping instructions', width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      ]

    basicFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.value

    customerFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.customer

    customerEmailFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.email

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
