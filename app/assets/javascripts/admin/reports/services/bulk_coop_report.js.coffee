angular.module("admin.reports").factory 'BulkCoopReport', (uiGridGroupingConstants) ->
  new class BulkCoopReport
    columnOptions: ->
      {bulk_coop_supplier_report: [
          { field: 'id',                             displayName: 'id',                   width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.producer.name',          displayName: 'Supplier',             width: '15%', sort: { priority: 0, direction: 'asc' }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.name',                   displayName: 'Product',              width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.group_buy_unit_size',    displayName: 'Bulk Unit size',       width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'full_name',                      displayName: 'Variant',              width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.value',                  displayName: 'Variant value',        width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.unit',                   displayName: 'Variant unit',         width: '10%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'variant.weight_from_unit_value', displayName: 'Weight',               width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'scaled_final_weight_volume',     displayName: 'Sum Total',            width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'units_required',                 displayName: 'Units required',       width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'remainder',                      displayName: 'Unallocated',          width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'max_quantity_excess',            displayName: 'Max quantity excess',  width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      ],
      bulk_coop_allocation: [
          { field: 'id',                             displayName: 'id',                   width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.producer.name',          displayName: 'Supplier',             width: '15%', sort: { priority: 0, direction: 'asc' }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.name',                   displayName: 'Product',              width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.group_buy_unit_size',    displayName: 'Bulk Unit size',       width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      ],
      bulk_coop_packing_sheets: [
          { field: 'id',                             displayName: 'id',                   width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.producer.name',          displayName: 'Supplier',             width: '15%', sort: { priority: 0, direction: 'asc' }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.name',                   displayName: 'Product',              width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.group_buy_unit_size',    displayName: 'Bulk Unit size',       width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
      ],
      bulk_coop_customer_payments: [
          { field: 'id',                             displayName: 'id',                   width: '5%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.producer.name',          displayName: 'Supplier',             width: '15%', sort: { priority: 0, direction: 'asc' }, groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.name',                   displayName: 'Product',              width: '15%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
          { field: 'product.group_buy_unit_size',    displayName: 'Bulk Unit size',       width: '8%', groupingShowAggregationMenu: false, groupingShowGroupingMenu: false }
        ]
      }

    gridOptions: ->
      enableSorting: true
      enableFiltering: true
      enableGridMenu: true
      exporterPdfDefaultStyle: {fontSize: 6 }
      exporterPdfTableHeaderStyle: { fontSize: 5, bold: true }
      exporterPdfTableStyle: { width: 'auto'}
      exporterPdfMaxGridWidth: 600
      columnDefs: this.columnOptions().bulk_coop_supplier_report

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
