angular.module("admin.reports").factory 'OrdersAndDistributorsReport', (uiGridGroupingConstants) ->
  new class OrdersAndDistributorsReport

    gridOptions: ->
      enableSorting: true
      enableFiltering: true
      enableGridMenu: true
      exporterPdfDefaultStyle: {fontSize: 6 }
      exporterPdfTableHeaderStyle: { fontSize: 5, bold: true }
      exporterPdfTableStyle: { width: 'auto'}
      exporterPdfMaxGridWidth: 600
      columnDefs: [
        { field: 'order.created_at',            displayName: 'Order date',            width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @orderDateFinalizer }
        { field: 'order.id',                    displayName: 'Order ID',              width: '6%',  visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 2 } }
        { field: 'order.customer',              displayName: 'Customer name',         width: '12%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerFinalizer }
        { field: 'order.email',                 displayName: 'Email',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerEmailFinalizer }
        { field: 'order.phone',                 displayName: 'Phone',                 width: '12%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerPhoneFinalizer }
        { field: 'order.city',                  displayName: 'City',                  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerCityFinalizer }
        { field: 'variant.sku',                 displayName: 'SKU',                   width: '5%',  groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.name',                displayName: 'Item name',             width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'full_name',                   displayName: 'Variant',               width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'quantity',                    displayName: 'Qty',                   width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'max_quantity',                displayName: 'Max Qty',               width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'cost',                        displayName: 'Cost',                  width: '5%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'distribution_fee',            displayName: 'Shipping Cost',         width: '5%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'order.payment_method',        displayName: 'Payment method',        width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @paymentMethodFinalizer }

        { field: 'order.distributor.name',      displayName: 'Distributor',           width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @distributorFinalizer }
        { field: 'order.distributor.address',   displayName: 'Distributor address',   width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @distributorAddressFinalizer }
        { field: 'order.distributor.city',      displayName: 'Distributor city',      width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @distributorCityFinalizer }
        { field: 'order.distributor.postcode',  displayName: 'Distributor postcode',  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @distributorPostcodeFinalizer }
        { field: 'order.special_instructions',  displayName: 'Shipping instructions', width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @shippingInstructionsFinalizer }
      ]

    basicFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.value

    customerFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.customer

    customerEmailFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.email

    orderDateFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.created_at

    customerPhoneFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.phone

    customerCityFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.city

    paymentMethodFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.payment_method

    distributorFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.distributor.name

    distributorAddressFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.distributor.address

    distributorCityFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.distributor.city

    distributorPostcodeFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.distributor.postcode

    shippingInstructionsFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.special_instructions

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
