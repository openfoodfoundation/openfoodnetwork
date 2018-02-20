describe "SubscriptionFunctions", ->
  subscription = null

  beforeEach ->
    module 'admin.subscriptions'
    module ($provide) ->
      $provide.value 'Customers', { byID: { 1: 'customer1' } }
      $provide.value 'Schedules', { byID: { 2: 'schedule2' } }
      $provide.value 'PaymentMethods', { byID: { 3: 'payment method 3' } }
      $provide.value 'ShippingMethods', { byID: { 4: 'shipping method 4' } }
      null

    inject ($injector, SubscriptionFunctions) ->
      class Subscription
      angular.extend(Subscription.prototype, SubscriptionFunctions)
      subscription = new Subscription

  describe "#customer", ->
    describe "when the id is not set", ->
      it "returns null", ->
        expect(subscription.customer()).toBeUndefined()

    describe "when the customer_id is set", ->
      beforeEach ->
        subscription.customer_id = 1

      it "looks up the customer from the Customers service", ->
        expect(subscription.customer()).toEqual 'customer1'

  describe "#schedule", ->
    describe "when the id is not set", ->
      it "returns null", ->
        expect(subscription.schedule()).toBeUndefined()

    describe "when the schedule_id is set", ->
      beforeEach ->
        subscription.schedule_id = 2

      it "looks up the schedule from the Schedules service", ->
        expect(subscription.schedule()).toEqual 'schedule2'

  describe "#paymentMethod", ->
    describe "when the id is not set", ->
      it "returns null", ->
        expect(subscription.paymentMethod()).toBeUndefined()

    describe "when the payment_method_id is set", ->
      beforeEach ->
        subscription.payment_method_id = 3

      it "looks up the payment_method from the PaymentMethods service", ->
        expect(subscription.paymentMethod()).toEqual 'payment method 3'

  describe "#shippingMethod", ->
    describe "when the id is not set", ->
      it "returns null", ->
        expect(subscription.shippingMethod()).toBeUndefined()

    describe "when the shipping_method_id is set", ->
      beforeEach ->
        subscription.shipping_method_id = 4

      it "looks up the shipping_method from the ShippingMethods service", ->
        expect(subscription.shippingMethod()).toEqual 'shipping method 4'
