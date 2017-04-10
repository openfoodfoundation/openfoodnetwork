angular.module("admin.reports").factory 'BulkCoopReport', (uiGridGroupingConstants) ->
  new class BulkCoopReport
    columnOptions: ->
      {supplier_report: [
          { field: 'id',                             displayName: 'Line Item ID',         width: '5%', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.producer.name',          displayName: 'Supplier',             width: '15%', sort: { priority: 0, direction: 'asc' }, grouping: { groupPriority: 1 }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.name',                   displayName: 'Product',              width: '15%', sort: { priority: 1, direction: 'asc' }, grouping: { groupPriority: 10 }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.group_buy_unit_size',    displayName: 'Bulk Unit size',       width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'full_name',                      displayName: 'Variant',              width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.value',                  displayName: 'Variant value',        width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.unit',                   displayName: 'Variant unit',         width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.weight_from_unit_value', displayName: 'Weight',               width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'scaled_final_weight_volume',     displayName: 'Sum Total',            width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'units_required',                 displayName: 'Units required',       width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'remainder',                      displayName: 'Unallocated',          width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'max_quantity_excess',            displayName: 'Max quantity excess',  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
      ],
      allocation: [
          { field: 'id',                             displayName: 'Line Item ID',         width: '5%', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'order.customer',                 displayName: 'Customer',             width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.name',                   displayName: 'Product',              width: '15%', sort: { priority: 0, direction: 'asc' }, grouping: { groupPriority: 0 }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.group_buy_unit_size',    displayName: 'Bulk Unit size',       width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'full_name',                      displayName: 'Variant',              width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.value',                  displayName: 'Variant value',        width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.unit',                   displayName: 'Variant unit',         width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.weight_from_unit_value', displayName: 'Weight',               width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'scaled_final_weight_volume',     displayName: 'Sum Total',            width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'total_available',                displayName: 'Total available',      width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
          { field: 'remainder',                      displayName: 'Unallocated',          width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'max_quantity_excess',            displayName: 'Max quantity excess',  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
      ],
      packing_sheets: [
          { field: 'id',                             displayName: 'Line Item ID',         width: '*', visible: false, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'order.customer',                 displayName: 'Customer',             width: '*', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.name',                   displayName: 'Product',              width: '*', sort: { priority: 0, direction: 'asc' }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'full_name',                      displayName: 'Variant',              width: '*', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'quantity',                       displayName: 'Sum total',            width: '*', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      ],
      customer_payments: [
          { field: 'order.id',                       displayName: 'Order ID',             width: '*', visible: false, grouping: { groupPriority: 0 }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'order.customer',                 displayName: 'Customer',             width: '*', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerFinalizer }
          { field: 'order.completed_at',             displayName: 'Date of order',        width: '*', sort: { priority: 0, direction: 'asc' }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @orderDateFinalizer  }
          { field: 'order.total',                    displayName: 'Total cost',           width: '*', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @orderTotalFinalizer  }
          { field: 'order.outstanding_balance',      displayName: 'Amount owing',         width: '*', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @orderOutstandingBalanceFinalizer  }
          { field: 'order.payment_total',            displayName: 'Amount paid',          width: '*', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @orderPaymentTotalFinalizer  }
        ]
      }

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
      columnDefs: this.columnOptions().supplier_report

    basicFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.value

    customerFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.customer

    customerEmailFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.email

    orderDateFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.completed_at

    orderTotalFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.total

    orderOutstandingBalanceFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.outstanding_balance

    orderPaymentTotalFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.payment_total

    orderAggregator: (aggregation, fieldValue, numValue, row) ->
      return if aggregation.order == row.entity.order
      if aggregation.order?
        aggregation.order = { }
      else
        aggregation.order = row.entity.order

    priceFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.display_total
