describe 'Variants service', ->
  Variants = null
  variant = null

  beforeEach ->
    variant =
      id: 1
      base_price: 80
      price: 100
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

  it "initialises base price percentage", ->
    expect(Variants.register(variant).basePricePercentage).toEqual 80
