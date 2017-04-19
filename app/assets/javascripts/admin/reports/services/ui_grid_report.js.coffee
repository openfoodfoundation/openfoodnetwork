angular.module("admin.reports").factory 'UIGridReport', ->
  class UIGridReport
    basicFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.value

    customerFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.customer

    customerEmailFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.email

    orderDateFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.created_at

    customerPhoneFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.bill_address.phone

    customerCityFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.bill_address.city

    paymentMethodFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.payment_method

    distributorFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.distributor.name

    distributorAddressFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.distributor.address1

    distributorCityFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.distributor.city

    distributorPostcodeFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.distributor.postcode

    shippingInstructionsFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.special_instructions

    sumAggregator: (aggregation, fieldValue, numValue, row) ->
      aggregation.value = 0 unless aggregation.sum?
      aggregation.value += numValue

    orderTotalFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.total

    orderOutstandingBalanceFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.outstanding_balance

    orderPaymentTotalFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.payment_total

    priceFinalizer: (aggregation) ->
      aggregation.rendered = aggregation.order.display_total

    productFinalizer: (aggregation) ->
      aggregation.rendered = "TOTAL"

    orderAggregator: (aggregation, fieldValue, numValue, row) ->
      return if aggregation.order == row.entity.order
      if aggregation.order?
        aggregation.order = { }
      else
        aggregation.order = row.entity.order
