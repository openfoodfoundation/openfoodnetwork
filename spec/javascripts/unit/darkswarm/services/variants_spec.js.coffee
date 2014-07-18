describe 'Variants service', ->
  Variants = null
  variant =
    id: 1

  beforeEach ->
    module 'Darkswarm'
    inject ($injector)->
      Variants =  $injector.get("Variants")

  it "will create a new variant", ->
    expect(Variants.register(variant)).toBe variant

  it "will return an existing variant rather than duplicating", ->
    Variants.register(variant)
    expect(Variants.register({id: 1})).toBe variant
