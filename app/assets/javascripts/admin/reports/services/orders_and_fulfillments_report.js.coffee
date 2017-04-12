angular.module("admin.reports").factory 'OrdersAndFulfillmentsReport', (uiGridGroupingConstants) ->
  new class OrdersAndFulfillmentsReport
    columnOptions: -> {
      supplier_totals: [
        { field: 'id',                      displayName: 'ID',                      width: '5%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.producer.name',   displayName: 'Producer',                width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, sort: { priority: 0, direction: 'asc' }, grouping: { groupPriority: 0 } }
        { field: 'product.name',            displayName: 'Product',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 0 }}
        { field: 'full_name',               displayName: 'Variant',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, grouping: { groupPriority: 0 } }
        { field: 'quantity',                displayName: 'Amount',                  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'total_units',             displayName: 'Total Units',             width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'price',                   displayName: 'Curr. Cost per Unit',     width: '12%', cellFilter: "customCurrency", groupingShowAggregationMenu: false }
        { field: 'cost',                    displayName: 'Total Cost',              width: '12%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
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
        { field: 'price',                   displayName: 'Curr. Cost per Unit',     width: '12%', cellFilter: "customCurrency", groupingShowAggregationMenu: false }
        { field: 'cost',                    displayName: 'Total Cost',              width: '12%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'default_value',           displayName: 'Shipping method',         width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, cellTemplate: '<div class="ui-grid-cell-contents">{{row.entity.default_value="shipping method"}}</div>' }

      ],
      distributor_totals_by_supplier: [
        { field: 'id',                      displayName: 'ID',                      width: '10%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.distributor.name',  displayName: 'Hub',                     width: '20%', sort: { priority: 0, direction: 'asc' }, grouping: { groupPriority: 0 }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.producer.name',   displayName: 'Producer',                width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.name',            displayName: 'Product',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'full_name',               displayName: 'Variant',                 width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'quantity',                displayName: 'Amount',                  width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'price',                   displayName: 'Curr. Cost per Unit',     width: '12%', cellFilter: "customCurrency", groupingShowAggregationMenu: false }
        { field: 'cost',                    displayName: 'Total Cost',              width: '12%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: ' ',                       displayName: 'Total shipping cost',     width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'default_value',           displayName: 'Shipping method',         width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, cellTemplate: '<div class="ui-grid-cell-contents">{{row.entity.default_value="shipping method"}}</div>' }
      ],
      customer_totals: [
        { field: 'id',                            displayName: 'ID',                 width: '10%', visible: true, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.distributor.name',        displayName: 'Hub',                width: '20%', sort: { priority: 0, direction: 'asc' }, grouping: { groupPriority: 0 }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.customer_id',             displayName: 'Customer ID',        width: '15%', visible: false, grouping: { groupPriority: 1 }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.customer',                displayName: 'Customer',           width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.email',                   displayName: 'Email',              width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerEmailFinalizer }
        { field: 'order.bill_address.phone',      displayName: 'Phone',              width: '12%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @orderAggregator, customTreeAggregationFinalizerFn: @customerPhoneFinalizer }
        { field: 'product.producer.name',         displayName: 'Producer',           width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'product.name',                  displayName: 'Product',            width: '20%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'full_name',                     displayName: 'Variant',            width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'quantity',                      displayName: 'Amount',             width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'cost',                          displayName: 'Price',              width: '8%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'cost_with_fees',                displayName: 'Price with fees',    width: '12%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.SUM, customTreeAggregationFinalizerFn: @basicFinalizer }
        { field: 'order.admin_and_handling_total',displayName: 'Admin & Handling',   width: '10%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.ship_total',              displayName: 'Ship',               width: '5%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.payment_fee',             displayName: 'Pay fee',            width: '5%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.total',                   displayName: 'Total',              width: '8%', cellFilter: "customCurrency", groupingShowAggregationMenu: false, groupingShowGroupingMenu: false, treeAggregationType: uiGridGroupingConstants.aggregation.CUSTOM, customTreeAggregationFn: @customOrderAggregator, customTreeAggregationFinalizerFn: @orderTotalFinalizer }
        { field: 'paid',                          displayName: 'Paid?',              width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.shipping_method',         displayName: 'Shipping',           width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.require_ship_address',    displayName: 'Delivery?',          width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.ship_address.address1',   displayName: 'Ship Street',        width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.ship_address.address2',   displayName: 'Ship Street 2',      width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.ship_address.city',       displayName: 'Ship City',          width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.ship_address.zipcode',    displayName: 'Ship Postcode',      width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.ship_address.state.name', displayName: 'Ship State',         width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: ' ',                             displayName: 'Comments',           width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'variant.sku',                   displayName: 'SKU',                width: '5%',  groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order_cycle_name.name',         displayName: 'Order Cycle',        width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.payment_method',          displayName: 'Payment Method',     width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.customer_code',           displayName: 'Customer code',      width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.customer_tgas',           displayName: 'Tags',               width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.bill_address.address1',   displayName: 'Billing Street 1',   width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.bill_address.address2',   displayName: 'Billing Street 2',   width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.bill_address.city',       displayName: 'Billing City',       width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.bill_address.zipcode',    displayName: 'Billing Postcode',   width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        { field: 'order.bill_address.state.name', displayName: 'Billing State',      width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      ]
    }

    @arrayInclude: (list, obj) ->
      return _.filter(list, (listItem) ->
        return angular.equals(listItem, obj)
      ).length > 0

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

    orderTotalFinalizer: (aggregation) ->
      if !aggregation.order.total?
        aggregation.rendered = aggregation.stats.sum
      else
        aggregation.rendered = aggregation.order.total

    # Aggregator for orderTotalFinalizer
    # it sums up only by order (not by LineItem)
    # TODO - make it recursive or configurable or test it so it would not break if third grouping would be introduced
    customOrderAggregator: (aggregation, fieldValue, numValue, row) ->
      return if aggregation.order == row.entity.order

      if not aggregation.stats?
        aggregation.stats = {orders: [], sum: 0}

      if not aggregation.order?
        aggregation.order = row.entity.order
      else
        aggregation.order = {}

      # check if order's total value is already in the cache
      if not OrdersAndFulfillmentsReport.arrayInclude(aggregation.stats.orders, {id: row.entity.order.id, value: numValue})
        aggregation.stats.orders.push({id: row.entity.order.id, value: numValue})
        aggregation.stats.sum += numValue

    orderAggregator: (aggregation, fieldValue, numValue, row) ->
      return if aggregation.order == row.entity.order
      if aggregation.order?
        aggregation.order = { }
      else
        aggregation.order = row.entity.order
