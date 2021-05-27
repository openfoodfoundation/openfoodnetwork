describe "UnitPrices service", ->
  UnitPrices = null
  currencyconfig =
    symbol: "$"
    symbol_position: "before"
    currency: "D"
    hide_cents: "false"
  
  beforeEach ->
    module "admin.products"
    module ($provide)->
      $provide.value "availableUnits", "g,kg,T,mL,L,kL,oz,lb"
      $provide.value "currencyConfig", currencyconfig
      null
    inject (_UnitPrices_) ->
      UnitPrices = _UnitPrices_

  describe "get correct unit price duo unit/value for weight", ->
    unit_type = "weight"

    it "with scale: 1", ->
      price = 1
      scale = 1
      unit_value = 1
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 1000
      expect(UnitPrices.unit(scale, unit_type)).toEqual "kg"

    it "with scale and unit_value: 1000", ->
      price = 1
      scale = 1000
      unit_value = 1000
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 1
      expect(UnitPrices.unit(scale, unit_type)).toEqual "kg"

    it "with scale: 1000 and unit_value: 2000", ->
      price = 1
      scale = 1000
      unit_value = 2000
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 0.5
      expect(UnitPrices.unit(scale, unit_type)).toEqual "kg"

    it "with price: 2", ->
      price = 2
      scale = 1
      unit_value = 1
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 2000
      expect(UnitPrices.unit(scale, unit_type)).toEqual "kg"

    it "with price: 2, scale and unit_value: 1000", ->
      price = 2
      scale = 1000
      unit_value = 1000
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 2
      expect(UnitPrices.unit(scale, unit_type)).toEqual "kg"

    it "with price: 2, scale: 1000 and unit_value: 2000", ->
      price = 2
      scale = 1000
      unit_value = 2000
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 1
      expect(UnitPrices.unit(scale, unit_type)).toEqual "kg"

    it "with price: 2, scale: 1000 and unit_value: 500", ->
      price = 2
      scale = 1000
      unit_value = 500
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 4
      expect(UnitPrices.unit(scale, unit_type)).toEqual "kg"


  describe "get correct unit price duo unit/value for volume", ->
    unit_type = "volume"

    it "with scale: 1", ->
      price = 1
      scale = 1
      unit_value = 1
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 1
      expect(UnitPrices.unit(scale, unit_type)).toEqual "L"

    it "with price: 2 and unit_value: 0.5", ->
      price = 2
      scale = 1
      unit_value = 0.5
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 4
      expect(UnitPrices.unit(scale, unit_type)).toEqual "L"

    it "with price: 2, scale: 0.001 and unit_value: 0.01", ->
      price = 2
      scale = 0.001
      unit_value = 0.01 
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 200
      expect(UnitPrices.unit(scale, unit_type)).toEqual "L"

    it "with price: 20000, scale: 1000 and unit_value: 10000", ->
      price = 20000
      scale = 1000
      unit_value = 10000 
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 2
      expect(UnitPrices.unit(scale, unit_type)).toEqual "L"

  describe "get correct unit price duo unit/value for items", ->
    unit_type = "items"
    scale = null

    it "with price: 1 and unit_value: 1", ->
      price = 1
      unit_value = 1
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 1
      expect(UnitPrices.unit(scale, unit_type)).toEqual "item"

    it "with price: 1 and unit_value: 10", ->
      price = 1
      unit_value = 10
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 0.1
      expect(UnitPrices.unit(scale, unit_type)).toEqual "item"

    it "with price: 10 and unit_value: 1", ->
      price = 10
      unit_value = 1
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 10
      expect(UnitPrices.unit(scale, unit_type)).toEqual "item"


  describe "get correct unit price duo unit/value for weight in imperial system", ->
    unit_type = "weight"

    it "with price: 1 and scale/unit_value: 28.35 (OZ)", ->
      price = 1
      scale = 28.35
      unit_value = 28.35
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 16
      expect(UnitPrices.unit(scale, unit_type)).toEqual "lb"

    it "with price: 1 and scale/unit_value: 453.6 (LB)", ->
      price = 1
      scale = 453.6
      unit_value = 453.6
      expect(UnitPrices.price(price, scale, unit_type, unit_value)).toEqual 1
      expect(UnitPrices.unit(scale, unit_type)).toEqual "lb"

  describe "get unit price when price is a decimal string", ->
    unit_type = "weight"

    it "with price: '1,0'", ->
      price = '1,0'
      scale = 1
      unit_value = 1
      expect(UnitPrices.displayableUnitPrice(price, scale, unit_type, unit_value)).toEqual "$1,000.00 / kg"

    it "with price: '1.0'", ->
      price = '1.0'
      scale = 1
      unit_value = 1
      expect(UnitPrices.displayableUnitPrice(price, scale, unit_type, unit_value)).toEqual "$1,000.00 / kg"
    