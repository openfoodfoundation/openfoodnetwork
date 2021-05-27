describe 'convert string to number with configurated currency', ->
  filter = null

  beforeEach ->
    module 'ofn.admin'
    inject ($filter) ->
      filter = $filter('unlocalizeCurrency')

  describe "with point as decimal separator and comma as thousands separator for I18n service", ->

    beforeEach ->
      spyOn(I18n,'toCurrency').and.callFake (arg) -> 
        if (arg == 0.1)
          return "0.1" 
        else if (arg == 1000)
          return "1,000"
    
    it "handle point as decimal separator", ->
      expect(filter("1.00")).toEqual 1.0

    it "handle point as decimal separator", ->
      expect(filter("1.000")).toEqual 1.0

    it "also handle comma as decimal separator", ->
      expect(filter("1,00")).toEqual 1.0

    it "handle point as decimal separator and comma as thousands separator", ->
      expect(filter("1,000,000.00")).toEqual 1000000

    it "handle integer number", ->
      expect(filter("10")).toEqual 10

    it "handle integer number with comma as thousands separator", ->
      expect(filter("1,000")).toEqual 1000
    
    it "handle integer number with no thousands separator", ->
      expect(filter("1000")).toEqual 1000
  
  describe "with comma as decimal separator and final point as thousands separator for I18n service", ->

    beforeEach ->
      spyOn(I18n,'toCurrency').and.callFake (arg) -> 
        if (arg == 0.1)
          return "0,1" 
        else if (arg == 1000)
          return "1.000"
    
    it "handle comma as decimal separator", ->
      expect(filter("1,00")).toEqual 1.0
    
    it "also handle point as decimal separator", ->
      expect(filter("1.00")).toEqual 1.0

    it "handle point as decimal separator and final point as thousands separator", ->
      expect(filter("1.000.000,00")).toEqual 1000000

    it "handle integer number", ->
      expect(filter("10")).toEqual 10

    it "handle integer number with final point as thousands separator", ->
      expect(filter("1.000")).toEqual 1000

    it "handle integer number with no thousands separator", ->
      expect(filter("1000")).toEqual 1000

  describe "with comma as decimal separator and space as thousands separator for I18n service", ->

    beforeEach ->
      spyOn(I18n,'toCurrency').and.callFake (arg) -> 
        if (arg == 0.1)
          return "0,1" 
        else if (arg == 1000)
          return "1 000"
    
    it "handle comma as decimal separator", ->
      expect(filter("1,00")).toEqual 1.0

    it "also handle final point as decimal separator", ->
      expect(filter("1.00")).toEqual 1.0

    it "handle point as decimal separator and space as thousands separator", ->
      expect(filter("1 000 000,00")).toEqual 1000000

    it "handle integer number", ->
      expect(filter("10")).toEqual 10

    it "handle integer number with space as thousands separator", ->
      expect(filter("1 000")).toEqual 1000

    it "handle integer number with no thousands separator", ->
      expect(filter("1000")).toEqual 1000
