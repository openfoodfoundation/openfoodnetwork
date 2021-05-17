describe 'convert string to number with configurated currency', ->
  filter = null

  beforeEach ->
    module 'ofn.admin'
    inject ($filter) ->
      filter = $filter('unlocalizeCurrency')

  describe "with point as decimal separator for I18n service", ->

    beforeEach -> 
      spyOn(I18n, "toCurrency").and.returnValue "0.1"

    it "handle point as decimal separator", ->
      expect(filter("1.0")).toEqual 1.0

    it "handle comma as decimal separator", ->
      expect(filter("1,0")).toEqual 1.0

  describe "with comma as decimal separator for I18n service", ->

    beforeEach -> 
      spyOn(I18n, "toCurrency").and.returnValue "0,1"

    it "handle point as decimal separator", ->
      expect(filter("1.0")).toEqual 1.0

    it "handle comma as decimal separator", ->
      expect(filter("1,0")).toEqual 1.0
