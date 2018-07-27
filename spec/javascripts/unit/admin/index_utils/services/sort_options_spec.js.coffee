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

  describe "sorting by a column", ->
    describe "when selecting Column A once", ->
      it "sorts by Column A", ->
        SortOptions.toggle("column.a")
        expect(SortOptions.predicate).toEqual "column.a"
        expect(SortOptions.reverse).toBe false

    describe "when selecting Column A twice", ->
      it "sorts by Column A in reverse order", ->
        SortOptions.toggle("column.a")
        SortOptions.toggle("column.a")
        expect(SortOptions.predicate).toEqual "column.a"
        expect(SortOptions.reverse).toBe true

    describe "when selecting Column A once then selecting Column B once", ->
      it "sorts by Column B", ->
        SortOptions.toggle("column.a")
        SortOptions.toggle("column.b")
        expect(SortOptions.predicate).toEqual "column.b"
        expect(SortOptions.reverse).toBe false

    describe "when selecting Column A twice then selecting Column B once", ->
      it "sorts by Column B in reverse order", ->
        SortOptions.toggle("column.a")
        SortOptions.toggle("column.a")
        SortOptions.toggle("column.b")
        expect(SortOptions.predicate).toEqual "column.b"
        expect(SortOptions.reverse).toBe false
