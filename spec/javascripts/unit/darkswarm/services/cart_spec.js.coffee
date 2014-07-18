describe 'Cart service', ->
  Cart = null
  Variants = null
  variant = {id: 1}
  order = {
    line_items: [
      variant: variant 
    ]
  }

  beforeEach ->
    module 'Darkswarm'
    angular.module('Darkswarm').value('currentOrder', order)
    inject ($injector)->
      Variants =  $injector.get("Variants")
      Cart =  $injector.get("Cart")

  it "backreferences line items", ->
    expect(Cart.line_items[0].variant.line_item).toBe Cart.line_items[0]

  it "registers variants with the Variants service", ->
    expect(Variants.variants[1]).toBe variant

  it "creates and backreferences new line items if necessary", ->
    Cart.register_variant(v2 = {id: 2})
    expect(Cart.line_items[1].variant).toBe v2 
    expect(Cart.line_items[1].variant.line_item).toBe Cart.line_items[1] 

  it "returns a list of items actually in the cart", ->
    expect(Cart.line_items_present()).toEqual []
    order.line_items[0].quantity = 1
    expect(Cart.line_items_present().length).toEqual 1
