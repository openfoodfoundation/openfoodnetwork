describe "PriceParser service", ->
  priceParser = null

  beforeEach ->
    module('admin.utils')
    inject (PriceParser) ->
      priceParser = PriceParser

  describe "test internal method with Regexp", -> 
    describe "test replaceCommaByFinalPoint() method", ->
      it "handle the default case (with two numbers after comma)", ->
        expect(priceParser.replaceCommaByFinalPoint("1,00")).toEqual "1.00"
      it "doesn't confuse with thousands separator", ->
        expect(priceParser.replaceCommaByFinalPoint("1,000")).toEqual "1,000"
      it "handle also when there is only one number after the decimal separator", ->
        expect(priceParser.replaceCommaByFinalPoint("1,0")).toEqual "1.0"
    describe "test removeThousandsSeparator() method", ->
      it "handle the default case", ->
        expect(priceParser.removeThousandsSeparator("1,000", ",")).toEqual "1000"
        expect(priceParser.removeThousandsSeparator("1,000,000", ",")).toEqual "1000000"
      it "handle the case with decimal separator", ->
         expect(priceParser.removeThousandsSeparator("1,000,000.00", ",")).toEqual "1000000.00"
      it "handle the case when it is actually a decimal separator (and not a thousands one)", ->
         expect(priceParser.removeThousandsSeparator("1,00", ",")).toEqual "1,00"

  describe "with point as decimal separator and comma as thousands separator for I18n service", ->

    beforeEach ->
      spyOn(I18n,'toCurrency').and.callFake (arg) -> 
        if (arg == 0.1)
          return "0.1" 
        else if (arg == 1000)
          return "1,000"
    
    it "handle point as decimal separator", ->
      expect(priceParser.parse("1.00")).toEqual 1.0

    it "handle point as decimal separator", ->
      expect(priceParser.parse("1.000")).toEqual 1.0

    it "also handle comma as decimal separator", ->
      expect(priceParser.parse("1,0")).toEqual 1.0

    it "also handle comma as decimal separator", ->
      expect(priceParser.parse("1,00")).toEqual 1.0

    it "also handle comma as decimal separator", ->
      expect(priceParser.parse("11,00")).toEqual 11.0

    it "handle comma as decimal separator but not confusing with thousands separator", ->
      expect(priceParser.parse("11,000")).toEqual 11000

    it "handle point as decimal separator and comma as thousands separator", ->
      expect(priceParser.parse("1,000,000.00")).toEqual 1000000

    it "handle integer number", ->
      expect(priceParser.parse("10")).toEqual 10

    it "handle integer number with comma as thousands separator", ->
      expect(priceParser.parse("1,000")).toEqual 1000
    
    it "handle integer number with no thousands separator", ->
      expect(priceParser.parse("1000")).toEqual 1000
  
  describe "with comma as decimal separator and final point as thousands separator for I18n service", ->

    beforeEach ->
      spyOn(I18n,'toCurrency').and.callFake (arg) -> 
        if (arg == 0.1)
          return "0,1" 
        else if (arg == 1000)
          return "1.000"
    
    it "handle comma as decimal separator", ->
      expect(priceParser.parse("1,00")).toEqual 1.0

    it "handle comma as decimal separator with one digit after the comma", ->
      expect(priceParser.parse("11,0")).toEqual 11.0

    it "handle comma as decimal separator with two digit after the comma", ->
      expect(priceParser.parse("11,00")).toEqual 11.0

    it "handle comma as decimal separator with three digit after the comma", ->
      expect(priceParser.parse("11,000")).toEqual 11.0
    
    it "also handle point as decimal separator", ->
      expect(priceParser.parse("1.00")).toEqual 1.0

    it "also handle point as decimal separator with integer part with two digits", ->
      expect(priceParser.parse("11.00")).toEqual 11.0

    it "handle point as decimal separator and final point as thousands separator", ->
      expect(priceParser.parse("1.000.000,00")).toEqual 1000000

    it "handle integer number", ->
      expect(priceParser.parse("10")).toEqual 10

    it "handle integer number with final point as thousands separator", ->
      expect(priceParser.parse("1.000")).toEqual 1000

    it "handle integer number with no thousands separator", ->
      expect(priceParser.parse("1000")).toEqual 1000

  describe "with comma as decimal separator and space as thousands separator for I18n service", ->

    beforeEach ->
      spyOn(I18n,'toCurrency').and.callFake (arg) -> 
        if (arg == 0.1)
          return "0,1" 
        else if (arg == 1000)
          return "1 000"
    
    it "handle comma as decimal separator", ->
      expect(priceParser.parse("1,00")).toEqual 1.0

    it "handle comma as decimal separator with one digit after the comma", ->
      expect(priceParser.parse("11,0")).toEqual 11.0

    it "handle comma as decimal separator with two digit after the comma", ->
      expect(priceParser.parse("11,00")).toEqual 11.0

    it "handle comma as decimal separator with three digit after the comma", ->
      expect(priceParser.parse("11,000")).toEqual 11.0

    it "also handle final point as decimal separator", ->
      expect(priceParser.parse("1.00")).toEqual 1.0

    it "also handle final point as decimal separator with integer part with two digits", ->
      expect(priceParser.parse("11.00")).toEqual 11.0

    it "handle point as decimal separator and space as thousands separator", ->
      expect(priceParser.parse("1 000 000,00")).toEqual 1000000

    it "handle integer number", ->
      expect(priceParser.parse("10")).toEqual 10

    it "handle integer number with space as thousands separator", ->
      expect(priceParser.parse("1 000")).toEqual 1000

    it "handle integer number with no thousands separator", ->
      expect(priceParser.parse("1000")).toEqual 1000
  
  describe "handle null/undefined case", ->
    it "null case", ->
      expect(priceParser.parse(null)).toEqual null
    
    it "undefined case ", ->
      expect(priceParser.parse(undefined)).toEqual null

    it "wtf case", ->
      expect(priceParser.parse("wtf")).toEqual null

