describe 'OrderCycle service', ->
  $httpBackend = null
  OrderCycle = null
  mockProduct = {
    update: ->
  }

  beforeEach ->
    module 'Shop', ($provide)->
      $provide.value "Product", mockProduct
      null # IMPORTANT
      # You must return null because module() is a bit dumb
    inject (_OrderCycle_, _$httpBackend_)->
      $httpBackend = _$httpBackend_
      OrderCycle = _OrderCycle_

  
  it "posts the order_cycle ID and tells product to update", ->
    $httpBackend.expectPOST("/shop/order_cycle", {"order_cycle_id" : 10}).respond(200)
    spyOn(mockProduct, "update")
    OrderCycle.set_order_cycle(10)
    $httpBackend.flush()
    expect(mockProduct.update).toHaveBeenCalled()


