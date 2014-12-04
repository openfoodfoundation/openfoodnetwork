describe "VariantOverrides service", ->
  VariantOverrides = null
  variantOverrides = [
    {id: 1, hub_id: 10, variant_id: 100, price: 1, count_on_hand: 1}
    {id: 2, hub_id: 10, variant_id: 200, price: 2, count_on_hand: 2}
    {id: 3, hub_id: 20, variant_id: 300, price: 3, count_on_hand: 3}
  ]

  beforeEach ->
    module "ofn.admin"
    module ($provide) ->
      $provide.value "variantOverrides", variantOverrides
      null

  beforeEach inject (_VariantOverrides_) ->
    VariantOverrides = _VariantOverrides_

  it "indexes variant overrides by hub_id -> variant_id", ->
    expect(VariantOverrides.variantOverrides).toEqual
      10:
        100: {id: 1, hub_id: 10, variant_id: 100, price: 1, count_on_hand: 1}
        200: {id: 2, hub_id: 10, variant_id: 200, price: 2, count_on_hand: 2}
      20:
        300: {id: 3, hub_id: 20, variant_id: 300, price: 3, count_on_hand: 3}
