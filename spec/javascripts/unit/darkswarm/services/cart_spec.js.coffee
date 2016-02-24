describe 'Cart service', ->
  Cart = null
  Variants = null
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
    inject ($injector, _$httpBackend_, _$timeout_)->
      Variants =  $injector.get("Variants")
      Cart =  $injector.get("Cart")
      $httpBackend = _$httpBackend_
      $timeout = _$timeout_

  it "backreferences line items", ->
    expect(Cart.line_items[0].variant.line_item).toBe Cart.line_items[0]

  it "registers variants with the Variants service", ->
    expect(Variants.variants[1]).toBe variant

  it "generates extended variant names", ->
    expect(Cart.line_items[0].variant.extended_name).toEqual "name"

  it "creates and backreferences new line items if necessary", ->
    Cart.register_variant(v2 = {id: 2})
    expect(Cart.line_items[1].variant).toBe v2
    expect(Cart.line_items[1].variant.line_item).toBe Cart.line_items[1]

  it "returns a list of items actually in the cart", ->
    expect(Cart.line_items_present()).toEqual []
    order.line_items[0].quantity = 1
    expect(Cart.line_items_present().length).toEqual

  it "sums the quantity of each line item for cart total", ->
    expect(Cart.line_items_present()).toEqual []
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

    it "sets update_running during the update, and clears it on success", ->
      $httpBackend.expectPOST("/orders/populate", data).respond 200, {}
      expect(Cart.update_running).toBe(false)
      Cart.update()
      expect(Cart.update_running).toBe(true)
      $httpBackend.flush()
      expect(Cart.update_running).toBe(false)

    it "sets update_running during the update, and clears it on failure", ->
      $httpBackend.expectPOST("/orders/populate", data).respond 404, {}
      expect(Cart.update_running).toBe(false)
      Cart.update()
      expect(Cart.update_running).toBe(true)
      $httpBackend.flush()
      expect(Cart.update_running).toBe(false)

    it "marks the form as saved on success", ->
      spyOn(Cart, 'saved')
      $httpBackend.expectPOST("/orders/populate", data).respond 200, {}
      Cart.update()
      $httpBackend.flush()
      expect(Cart.saved).toHaveBeenCalled()

    it "runs enqueued updates after success", ->
      Cart.update_enqueued = true
      spyOn(Cart, 'saved')
      spyOn(Cart, 'popQueue')
      $httpBackend.expectPOST("/orders/populate", data).respond 200, {}
      Cart.update()
      $httpBackend.flush()
      expect(Cart.popQueue).toHaveBeenCalled()

    it "doesn't run an update if it's not enqueued", ->
      Cart.update_enqueued = false
      spyOn(Cart, 'saved')
      spyOn(Cart, 'popQueue')
      $httpBackend.expectPOST("/orders/populate", data).respond 200, {}
      Cart.update()
      $httpBackend.flush()
      expect(Cart.popQueue).not.toHaveBeenCalled()

    it "retries the update on failure", ->
      spyOn(Cart, 'scheduleRetry')
      $httpBackend.expectPOST("/orders/populate", data).respond 404, {}
      Cart.update()
      $httpBackend.flush()
      expect(Cart.scheduleRetry).toHaveBeenCalled()

  it "pops the queue", ->
    Cart.update_enqueued = true
    spyOn(Cart, 'scheduleUpdate')
    Cart.popQueue()
    expect(Cart.update_enqueued).toBe(false)
    expect(Cart.scheduleUpdate).toHaveBeenCalled()

  it "schedules retries of updates", ->
    spyOn(Cart, 'orderChanged')
    Cart.scheduleRetry()
    $timeout.flush()
    expect(Cart.orderChanged).toHaveBeenCalled()

  it "clears the cart", ->
    expect(Cart.line_items).not.toEqual []
    Cart.clear()
    expect(Cart.line_items).toEqual []

  describe "generating an extended variant name", ->
    it "returns the product name when it is the same as the variant name", ->
      variant = {product_name: 'product_name', name_to_display: 'product_name'}
      expect(Cart.extendedVariantName(variant)).toEqual "product_name"

    describe "when the product name and the variant name differ", ->
      it "returns a combined name when there is no options text", ->
        variant =
          product_name: 'product_name'
          name_to_display: 'name_to_display'
        expect(Cart.extendedVariantName(variant)).toEqual "product_name - name_to_display"

      it "returns a combined name when there is some options text", ->
        variant =
          product_name: 'product_name'
          name_to_display: 'name_to_display'
          options_text: 'options_text'

        expect(Cart.extendedVariantName(variant)).toEqual "product_name - name_to_display (options_text)"
