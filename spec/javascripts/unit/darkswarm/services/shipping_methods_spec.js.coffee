describe "Shipping method service", ->
  ShippingMethods = null
  shippingMethods = [
    {id: 1, price: "1.2"}
  ]

  beforeEach ->
    module 'Darkswarm'
    angular.module('Darkswarm').value('shippingMethods', shippingMethods)
    inject ($injector)->
      ShippingMethods = $injector.get("ShippingMethods")

  it "converts price to float", ->
    expect(ShippingMethods.shipping_methods[0].price).toEqual 1.2
