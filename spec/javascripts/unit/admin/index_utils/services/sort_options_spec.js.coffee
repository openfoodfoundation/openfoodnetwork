describe "SortOptions service", ->
  SortOptions = null

  beforeEach ->
    module 'admin.indexUtils'
    inject (_SortOptions_) ->
      SortOptions = _SortOptions_

  describe "initialising predicate", ->
    it "sets predicate to blank", ->
      expect(SortOptions.predicate).toEqual ""

  describe "initialising reverse", ->
    it "sets reverse to true", ->
      expect(SortOptions.reverse).toBe true
