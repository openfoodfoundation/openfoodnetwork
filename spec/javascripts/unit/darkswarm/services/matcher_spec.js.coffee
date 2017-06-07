describe 'Matcher service', ->
  Matcher = null

  beforeEach ->
    module 'Darkswarm'
    inject ($injector)->
      Matcher = $injector.get("Matcher")

  describe '#match', ->
    it "matches full word", ->
      expect(Matcher.match ["product_name"], "product_name").toEqual true

    it "matches second word", ->
      expect(Matcher.match ["product_name", 'variant'], "variant").toEqual true

    it "matches word with underscore", ->
      expect(Matcher.match ["product_name"], "ct_na").toEqual true

    it "matches word if property has two words", ->
      expect(Matcher.match ["product name"], "nam").toEqual true

    it "matches word with dash", ->
      expect(Matcher.match ["product-name"], "ct-na").toEqual true

    it "finds in any part of properties", ->
      expect(Matcher.match ["keyword"], "word").toEqual true

    it "finds beginning of property", ->
      expect(Matcher.match ["keyword"], "key").toEqual true

    it "doesn't find non-sense or mistypes", ->
      expect(Matcher.match ["keyword"], "keywrd").toEqual false

  describe '#matchBeginning', ->
    it "matches full word", ->
      expect(Matcher.matchBeginning ["product_name"], "product_name").toEqual true

    it "matches second word", ->
      expect(Matcher.matchBeginning ["product_name", 'variant'], "variant").toEqual true

    it "matches word if property has two words", ->
      expect(Matcher.matchBeginning ["product name"], "nam").toEqual true

    it "matches second part of word separated by dash", ->
      expect(Matcher.matchBeginning ["product-name"], "name").toEqual true

    it "matches beginning of property", ->
      expect(Matcher.matchBeginning ["keyword"], "key").toEqual true

    it "doesn't match in any part of property", ->
      expect(Matcher.matchBeginning ["keyword"], "word").toEqual false

    it "doesn't match non-sense or mistypes", ->
      expect(Matcher.matchBeginning ["keyword"], "keywrd").toEqual false
