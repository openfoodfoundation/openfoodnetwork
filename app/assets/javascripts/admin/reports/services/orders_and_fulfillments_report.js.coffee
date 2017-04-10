angular.module("admin.reports").factory 'OrdersAndFulfillmentsReport', (uiGridGroupingConstants) ->
  new class OrdersAndFulfillmentsReport
    columnOptions: ->
      {
        supplier_totals: [
          { field: 'id',                      displayName: 'ID',                      width: '5%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.producer.name',   displayName: 'Producer',                width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, sort: { priority: 0, direction: 'asc' }, grouping: { groupPriority: 0 } }
          { field: 'product.name',            displayName: 'Product',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 0 }}
          { field: 'full_name',               displayName: 'Variant',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 0 } }
          { field: 'quantity',                displayName: 'Amount',                  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'total_units',             displayName: 'Total Units',             width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'price',                   displayName: 'Curr. Cost per Unit',     width: '5%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'cost',                    displayName: 'Total Cost',              width: '15%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: ' ',                       displayName: 'Status',                   width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'default_value',           displayName: 'Incoming Transport',      width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, cellTemplate: '<div class="ui-grid-cell-contents">{{row.entity.default_value="incoming transport"}}</div>' }
        ],
        supplier_totals_by_distributor: [
          { field: 'id',                      displayName: 'ID',                      width: '5%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.producer.name',   displayName: 'Producer',                width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, sort: { priority: 0, direction: 'asc' }, grouping: { groupPriority: 0 } }
          { field: 'product.name',            displayName: 'Product',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 0 }}
          { field: 'full_name',               displayName: 'Variant',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 0 } }
          { field: 'order.distributor.name',  displayName: 'To Hub',                  width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'quantity',                displayName: 'Amount',                  width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'price',                   displayName: 'Curr. Cost per Unit',     width: '10%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'cost',                    displayName: 'Total Cost',              width: '15%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'default_value',           displayName: 'Shipping method',         width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, cellTemplate: '<div class="ui-grid-cell-contents">{{row.entity.default_value="shipping method"}}</div>' }

        ],
        distributor_totals_by_supplier: [
          { field: 'id',                displayName: 'ID',                width: '10%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        ],
        customer_totals: [
          { field: 'id',                displayName: 'ID',                width: '10%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        ]
      }

    gridOptions: ->
      enableSorting: true
      enableFiltering: true
      enableGridMenu: true
      exporterPdfDefaultStyle: {fontSize: 6 }
      exporterPdfTableHeaderStyle: { fontSize: 5, bold: true }
      exporterPdfTableStyle: { width: 'auto'}
      columnDefs: this.columnOptions().supplier_totals
      # columnDefs: [
      #   { field: 'id',                displayName: 'ID',                width: '10%', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      #   { field: 'order.number',      displayName: 'Order',             width: '20%', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 1 } }
      #   { field: 'order.customer',    displayName: 'Customer',          width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, sort: { priority: 0, direction: 'asc' }, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerFinalizer }
      #   { field: 'order.email',       displayName: 'Email',             width: '20%', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      #   { field: 'product.name',      displayName: 'Product',           width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @productFinalizer }
      #   { field: 'full_name',         displayName: 'Variant',           width: '25%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      #   { field: 'quantity',          displayName: 'Qty',               width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
      #   { field: 'price',             displayName: 'Items',             width: '15%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
      #   { field: 'price_with_fees',   displayName: 'Items + Fees',      width: '15%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
      # ]

    gridOptions: ->
      enableSorting: true
      enableFiltering: true
      enableGridMenu: true
      exporterMenuAllData: false
      exporterMenuVisibleData: false
      exporterPdfDefaultStyle: {fontSize: 6 }
      exporterPdfTableHeaderStyle: { fontSize: 5, bold: true }
      exporterPdfTableStyle: { width: 'auto'}
      exporterPdfMaxGridWidth: 600
      columnDefs: this.columnOptions().supplier_totals

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
