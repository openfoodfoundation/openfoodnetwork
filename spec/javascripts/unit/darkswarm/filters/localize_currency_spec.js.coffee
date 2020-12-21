describe 'convert number to localised currency ', ->
  filter = currencyconfig = null

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
      filter = $filter('localizeCurrency')

  it "adds decimal fraction to an amount", ->
    expect(filter(10)).toEqual "$10.00"

  it "handles an existing fraction", ->
    expect(filter(9.9)).toEqual "$9.90"

  it "can use any currency symbol", ->
    currencyconfig.symbol = "£"
    expect(filter(404.04)).toEqual "£404.04"

  it "can place symbols after the amount", ->
    currencyconfig.symbol_position = "after"
    expect(filter(333.3)).toEqual "333.30$"

  it "can add a currency string", ->
    currencyconfig.display_currency = "true"
    expect(filter(5)).toEqual "$5.00 D"

  it "can hide cents", ->
    currencyconfig.hide_cents = "true"
    expect(filter(5)).toEqual "$5"
