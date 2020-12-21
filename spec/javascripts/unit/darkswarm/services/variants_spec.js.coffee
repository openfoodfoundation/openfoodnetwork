describe 'Variants service', ->
  Variants = null
  variant = null

  beforeEach ->
    variant =
      id: 1
      price: 80.5
      price_with_fees: 100
    module 'Darkswarm'
    inject ($injector)->
      Variants =  $injector.get("Variants")

  it "will create a new variant", ->
    expect(Variants.register(variant)).toBe variant

  it "will return an existing variant rather than duplicating", ->
    Variants.register(variant)
    expect(Variants.register({id: 1})).toBe variant

  it "will return the same object as passed", ->
    expect(Variants.register(variant)).toBe variant

  describe "initialising the line_item", ->
    describe "when variant.line_item does not exist", ->
      it "creates it", ->
        line_item = Variants.register(variant).line_item
        expect(line_item).toBeDefined()
        expect(line_item.total_price).toEqual 0

    describe "when variant.line_item already exists", ->
      beforeEach ->
        variant.line_item = { quantity: 4 }

      it "initialises the total_price", ->
        expect(Variants.register(variant).line_item.total_price).toEqual 400

  it "clears registered variants", ->
    Variants.register(variant)
    expect(Variants.variants[variant.id]).toBe variant
    Variants.clear()
    expect(Variants.variants[variant.id]).toBeUndefined()

  describe "generating an extended variant name", ->
    it "returns the product name when it is the same as the variant name", ->
      variant = {product_name: 'product_name', name_to_display: 'product_name'}
      expect(Variants.extendedVariantName(variant)).toEqual "product_name"

    describe "when the product name and the variant name differ", ->
      it "returns a combined name when there is no options text", ->
        variant =
          product_name: 'product_name'
          name_to_display: 'name_to_display'
        expect(Variants.extendedVariantName(variant)).toEqual "product_name - name_to_display"
