describe 'OrderCycle service', ->
  $httpBackend = null
  OrderCycle = null
  mockProduct = {
    update: ->
  }

  beforeEach ->
    angular.module('Darkswarm').value('orderCycleData', {})
    module 'Darkswarm', ($provide)->
      $provide.value "Product", mockProduct
      null # IMPORTANT
      # You must return null because module() is a bit dumb
      
    inject (_OrderCycle_, _$httpBackend_)->
      $httpBackend = _$httpBackend_
      OrderCycle = _OrderCycle_

  
  it "posts the order_cycle ID and tells product to update", ->
    $httpBackend.expectPOST("/shop/order_cycle", {"order_cycle_id" : 10}).respond(200)
    spyOn(mockProduct, "update")
    OrderCycle.order_cycle.order_cycle_id = 10
    OrderCycle.push_order_cycle mockProduct.update
    $httpBackend.flush()
    expect(mockProduct.update).toHaveBeenCalled()

  it "updates the orders_close_at attr after update", ->
    datestring = "2013-12-20T00:00:00+11:00" 
    $httpBackend.expectPOST("/shop/order_cycle").respond({orders_close_at: datestring})
    OrderCycle.push_order_cycle mockProduct.update
    $httpBackend.flush()
    expect(OrderCycle.order_cycle.orders_close_at).toEqual(datestring)

  it "tells us when the order cycle closes", ->
    OrderCycle.order_cycle.orders_close_at = "test"
    expect(OrderCycle.orders_close_at()).toEqual "test"

  it "tells us when no order cycle is selected", ->
    OrderCycle.order_cycle = null 
    expect(OrderCycle.selected()).toEqual false
    OrderCycle.order_cycle = {orders_close_at: "10 days ago"}
    expect(OrderCycle.selected()).toEqual true

