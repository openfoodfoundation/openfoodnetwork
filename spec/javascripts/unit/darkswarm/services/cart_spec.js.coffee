describe 'Cart service', ->
  Cart = null
  Variants = null
  RailsFlashLoader = null
  variant = null
  order = null
  $httpBackend = null
  $timeout = null

  beforeEach ->
    module 'Darkswarm'
    variant =
      id: 1
      name_to_display: 'name'
      product_name: 'name'
    order = {
      line_items: [
        variant: variant
      ]
    }
    angular.module('Darkswarm').value('currentOrder', order)

    module ($provide)->
      $provide.value "railsFlash", null
      null

    inject ($injector, _$httpBackend_, _$timeout_, _RailsFlashLoader_)->
      Variants =  $injector.get("Variants")
      Cart =  $injector.get("Cart")
      RailsFlashLoader = _RailsFlashLoader_
      $httpBackend = _$httpBackend_
      $timeout = _$timeout_

  it "backreferences line items", ->
    expect(Cart.line_items[0].variant.line_item).toBe Cart.line_items[0]

  it "registers variants with the Variants service", ->
    expect(Variants.variants[1]).toBe variant

  it "generates extended variant names", ->
    expect(Cart.line_items[0].variant.extended_name).toEqual "name"

  it "adds item to and removes items from the cart", ->
    Cart.line_items = []
    expect(Cart.line_items.length).toEqual 0
    order.line_items[0].quantity = 1
    expect(Cart.line_items.length).toEqual 0
    Cart.adjust(order.line_items[0])
    expect(Cart.line_items.length).toEqual 1
    order.line_items[0].quantity = 0
    expect(Cart.line_items.length).toEqual 1
    Cart.adjust(order.line_items[0])
    expect(Cart.line_items.length).toEqual 0

  it "does not add an item in the cart without quantity", ->
    Cart.line_items = []

    spyOn(Cart, 'orderChanged')
    order.line_items[0].max_quantity = 0
    expect(Cart.orderChanged).not.toHaveBeenCalled()

  it "sums the quantity of each line item for cart total", ->
    order.line_items[0].quantity = 2
    expect(Cart.total_item_count()).toEqual 2

  describe "triggering cart updates", ->
    it "schedules an update when there's no update running", ->
      Cart.update_running = false
      Cart.update_enqueued = false
      spyOn(Cart, 'scheduleUpdate')
      spyOn(Cart, 'unsaved')
      Cart.orderChanged()
      expect(Cart.scheduleUpdate).toHaveBeenCalled()

    it "enqueues an update when there's already an update running", ->
      Cart.update_running = true
      Cart.update_enqueued = false
      spyOn(Cart, 'scheduleUpdate')
      spyOn(Cart, 'unsaved')
      Cart.orderChanged()
      expect(Cart.scheduleUpdate).not.toHaveBeenCalled()
      expect(Cart.update_enqueued).toBe(true)

    it "does nothing when there's already an update enqueued", ->
      Cart.update_running = true
      Cart.update_enqueued = true
      spyOn(Cart, 'scheduleUpdate')
      spyOn(Cart, 'unsaved')
      Cart.orderChanged()
      expect(Cart.scheduleUpdate).not.toHaveBeenCalled()
      expect(Cart.update_enqueued).toBe(true)

  describe "updating the cart", ->
    data = {variants: {}}

    beforeEach ->
      spyOn(RailsFlashLoader, "loadFlash")

    it "sets update_running during the update, and clears it on success", ->
      $httpBackend.expectPOST("/cart/populate", data).respond 200, {}
      expect(Cart.update_running).toBe(false)
      Cart.update()
      expect(Cart.update_running).toBe(true)
      $httpBackend.flush()
      expect(Cart.update_running).toBe(false)

    it "sets update_running during the update, and clears it on failure", ->
      $httpBackend.expectPOST("/cart/populate", data).respond 404, {}
      expect(Cart.update_running).toBe(false)
      Cart.update()
      expect(Cart.update_running).toBe(true)
      $httpBackend.flush()
      expect(Cart.update_running).toBe(false)

    it "marks the form as saved on success", ->
      spyOn(Cart, 'saved')
      $httpBackend.expectPOST("/cart/populate", data).respond 200, {}
      Cart.update()
      $httpBackend.flush()
      expect(Cart.saved).toHaveBeenCalled()

    it "runs enqueued updates after success", ->
      Cart.update_enqueued = true
      spyOn(Cart, 'saved')
      spyOn(Cart, 'popQueue')
      $httpBackend.expectPOST("/cart/populate", data).respond 200, {}
      Cart.update()
      $httpBackend.flush()
      expect(Cart.popQueue).toHaveBeenCalled()

    it "doesn't run an update if it's not enqueued", ->
      Cart.update_enqueued = false
      spyOn(Cart, 'saved')
      spyOn(Cart, 'popQueue')
      $httpBackend.expectPOST("/cart/populate", data).respond 200, {}
      Cart.update()
      $httpBackend.flush()
      expect(Cart.popQueue).not.toHaveBeenCalled()

    it "shows an error on cart update failure", ->
      $httpBackend.expectPOST("/cart/populate", data).respond 412, {}
      Cart.update()
      $httpBackend.flush()
      expect(RailsFlashLoader.loadFlash).toHaveBeenCalled()

  describe "verifying stock levels after update", ->
    describe "when an item is out of stock", ->
      it "reduces the quantity in the cart", ->
        li = {variant: {id: 1}, quantity: 5}
        Cart.line_items = [li]
        stockLevels = {1: {quantity: 0, max_quantity: 0, on_hand: 0}}
        Cart.compareAndNotifyStockLevels stockLevels
        expect(li.quantity).toEqual 0
        expect(li.max_quantity).toBeUndefined()

      it "reduces the max_quantity in the cart", ->
        li = {variant: {id: 1}, quantity: 5, max_quantity: 6}
        Cart.line_items = [li]
        stockLevels = {1: {quantity: 0, max_quantity: 0, on_hand: 0}}
        Cart.compareAndNotifyStockLevels stockLevels
        expect(li.max_quantity).toEqual 0

      it "resets the count on hand available", ->
        li = {variant: {id: 1, on_hand: 10}, quantity: 5}
        Cart.line_items = [li]
        stockLevels = {1: {quantity: 0, max_quantity: 0, on_hand: 0}}
        Cart.compareAndNotifyStockLevels stockLevels
        expect(li.variant.on_hand).toEqual 0

    describe "when the quantity available is less than that requested", ->
      it "reduces the quantity in the cart", ->
        li = {variant: {id: 1}, quantity: 6}
        Cart.line_items = [li]
        stockLevels = {1: {quantity: 5, on_hand: 5}}
        Cart.compareAndNotifyStockLevels stockLevels
        expect(li.quantity).toEqual 5
        expect(li.max_quantity).toBeUndefined()

      it "does not reduce the max_quantity in the cart", ->
        li = {variant: {id: 1}, quantity: 6, max_quantity: 7}
        Cart.line_items = [li]
        stockLevels = {1: {quantity: 5, max_quantity: 5, on_hand: 5}}
        Cart.compareAndNotifyStockLevels stockLevels
        expect(li.max_quantity).toEqual 7

      it "resets the count on hand available", ->
        li = {variant: {id: 1}, quantity: 6}
        Cart.line_items = [li]
        stockLevels = {1: {quantity: 5, on_hand: 6}}
        Cart.compareAndNotifyStockLevels stockLevels
        expect(li.variant.on_hand).toEqual 6

    describe "when the client-side quantity has been increased during the request", ->
      it "does not reset the quantity", ->
        li = {variant: {id: 1}, quantity: 6}
        Cart.line_items = [li]
        stockLevels = {1: {quantity: 5, on_hand: 6}}
        Cart.compareAndNotifyStockLevels stockLevels
        expect(li.quantity).toEqual 6
        expect(li.max_quantity).toBeUndefined()

      it "does not reset the max_quantity", ->
        li = {variant: {id: 1}, quantity: 5, max_quantity: 7}
        Cart.line_items = [li]
        stockLevels = {1: {quantity: 5, max_quantity: 6, on_hand: 7}}
        Cart.compareAndNotifyStockLevels stockLevels
        expect(li.quantity).toEqual 5
        expect(li.max_quantity).toEqual 7

    describe "when the client-side quantity has been changed from 0 to 1 during the request", ->
      it "does not reset the quantity", ->
        li = {variant: {id: 1}, quantity: 1}
        Cart.line_items = [li]
        Cart.compareAndNotifyStockLevels {}
        expect(li.quantity).toEqual 1
        expect(li.max_quantity).toBeUndefined()

      it "does not reset the max_quantity", ->
        li = {variant: {id: 1}, quantity: 1, max_quantity: 1}
        Cart.line_items = [li]
        Cart.compareAndNotifyStockLevels {}
        expect(li.quantity).toEqual 1
        expect(li.max_quantity).toEqual 1

  describe "when modifying a confirmed order", ->
    it "displays flash error when attempting to remove final item", ->
      spyOn(RailsFlashLoader, 'loadFlash')
      li = {id: 1, order_id: 1, variant: {id: 1}, quantity: 3}
      li2 = {id: 2, order_id: 2, variant: {id: 2}, quantity: 1}
      Cart.line_items_finalised = [li, li2]
      expect(Cart.isOnlyItemInOrder(li.id)).toBe(true)

  it "pops the queue", ->
    Cart.update_enqueued = true
    spyOn(Cart, 'scheduleUpdate')
    Cart.popQueue()
    expect(Cart.update_enqueued).toBe(false)
    expect(Cart.scheduleUpdate).toHaveBeenCalled()

  it "clears the cart", ->
    expect(Cart.line_items).not.toEqual []
    Cart.clear()
    expect(Cart.line_items).toEqual []
