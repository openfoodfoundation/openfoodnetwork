# Provides additional auxillary functions to instances of SubscriptionResource
# Used to extend the extend the protype of the subscription resource created by SubscriptionResource

angular.module("admin.subscriptions").factory 'SubscriptionFunctions', ($injector) ->
  estimatedSubtotal: ->
    @subscription_line_items.reduce (subtotal, item) ->
      return subtotal if item._destroy
      subtotal += item.price_estimate * item.quantity
    , 0

  estimatedFees: ->
    @shipping_fee_estimate + @payment_fee_estimate

  estimatedTotal: ->
    @estimatedSubtotal() + @estimatedFees()

  customer: ->
    return unless @customer_id
    return unless $injector.has('Customers')
    $injector.get('Customers').byID[@customer_id]

  schedule: ->
    return unless @schedule_id
    return unless $injector.has('Schedules')
    $injector.get('Schedules').byID[@schedule_id]

  paymentMethod: ->
    return unless @payment_method_id
    return unless $injector.has('PaymentMethods')
    $injector.get('PaymentMethods').byID[@payment_method_id]

  shippingMethod: ->
    return unless @shipping_method_id
    return unless $injector.has('ShippingMethods')
    $injector.get('ShippingMethods').byID[@shipping_method_id]
