describe "ensuring unit price formatter", ->
  filter = null

  beforeEach ->
    currencyconfig =
      symbol: "$"
      symbol_position: "before"
      currency: "D"
      hide_cents: "false"
    module 'Darkswarm'
    module ($provide)->
      $provide.value "currencyConfig", currencyconfig
      null
    inject ($filter) ->
      filter = $filter 'formatUnitPrice'

  it "returns null when no price", ->
    expect(filter(null, "whatever")).toBeNull()

  it "returns wel formatted unit price", ->
    expect(filter(12, "kg")).toEqual "$12.00&nbsp;/&nbsp;kg"
