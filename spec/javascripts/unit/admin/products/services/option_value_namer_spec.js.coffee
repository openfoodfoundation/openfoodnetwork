describe "OptionValueNamer", ->
  subject = null

  beforeEach ->
    module('admin.products')
    module ($provide)->
      $provide.value "availableUnits", "g,kg,T,mL,L,kL"
      null
    inject (_OptionValueNamer_) ->
      subject = new _OptionValueNamer_

  describe "pluralize a variant unit name", ->
    it "returns the same word if no plural is known", ->
      expect(subject.pluralize("foo", 2)).toEqual "foo"

    it "returns the same word if we omit the quantity", ->
      expect(subject.pluralize("loaf")).toEqual "loaf"

    it "finds the plural of a word", ->
      expect(subject.pluralize("loaf", 2)).toEqual "loaves"

    it "finds the singular of a word", ->
      expect(subject.pluralize("loaves", 1)).toEqual "loaf"

    it "finds the zero form of a word", ->
      expect(subject.pluralize("loaf", 0)).toEqual "loaves"

    it "ignores upper case", ->
      expect(subject.pluralize("Loaf", 2)).toEqual "loaves"
