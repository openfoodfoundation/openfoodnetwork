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

    describe "getting the sorting expression", ->
      describe "when not specifying the default sort direction", ->
        it "sets the direction to 'asc' after the first toggle because the default direction is 'desc'", ->
          SortOptions.toggle("column.a")
          expect(SortOptions.getSortingExpr()).toEqual "column.a asc"

      describe "when specifying the default sorting direction as 'desc'", ->
        it "sets the direction to 'asc' after the first toggle", ->
          SortOptions.toggle("column.a")
          expect(SortOptions.getSortingExpr(defaultDirection: "desc")).toEqual "column.a asc"

      describe "when specifying the default sorting direction as 'asc'", ->
        it "sets the direction to 'desc' after the first toggle", ->
          SortOptions.toggle("column.a")
          expect(SortOptions.getSortingExpr(defaultDirection: "asc")).toEqual "column.a desc"
