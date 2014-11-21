describe "DisplayProperties", ->
  DisplayProperties = null

  beforeEach ->
    module "ofn.admin"

  beforeEach inject (_DisplayProperties_) ->
    DisplayProperties = _DisplayProperties_

  it "defaults showVariants to false", ->
    expect(DisplayProperties.showVariants(123)).toEqual false

  it "sets the showVariants value", ->
    DisplayProperties.setShowVariants(123, true)
    expect(DisplayProperties.showVariants(123)).toEqual true
    DisplayProperties.setShowVariants(123, false)
    expect(DisplayProperties.showVariants(123)).toEqual false
