describe 'convert number to localised currency ', ->
  filter = null

  currencyconfig =
    currency: "D"
    symbol: "$"
    symbol_position: "before"
    hide_cents: "false"
    decimal_mark: "."
    thousands_separator: ","

  beforeEach ->
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
    currencyconfig.symbol = "$"

  it "can place symbols after the amount", ->
    currencyconfig.symbol_position = "after"
    expect(filter(333.3)).toEqual "333.30 $"
    currencyconfig.symbol_position = "before"

  it "can add a currency string", ->
    currencyconfig.display_currency = "true"
    expect(filter(5)).toEqual "$5.00 D"
    currencyconfig.display_currency = "false"


