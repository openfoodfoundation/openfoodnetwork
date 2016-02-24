describe "Columns service", ->
  Columns = null

  beforeEach ->
    module 'admin.indexUtils'

    inject (_Columns_) ->
      Columns = _Columns_

  describe "setting columns", ->
    it "sets resets @columns and copies each column of the provided object across", ->
      Columns.setColumns({ name: { visible: true } })
      expect(Columns.columns).toEqual { name: { visible: true } }

    it "calls calculateVisibleCount", ->
      spyOn(Columns, "calculateVisibleCount")
      Columns.setColumns({ name: { visible: true } })
      expect(Columns.calculateVisibleCount).toHaveBeenCalled()

  describe "toggling a column", ->
    it "switches the visibility of the given column", ->
      column = { visible: false }
      Columns.toggleColumn(column)
      expect(column.visible).toBe true

    it "calls calculateVisibleCount", ->
      spyOn(Columns, "calculateVisibleCount")
      Columns.toggleColumn({ visible: false })
      expect(Columns.calculateVisibleCount).toHaveBeenCalled()

  describe "calculating visibleCount", ->
    it "counts the number of columns ", ->
      Columns.columns = { col1: { visible: false }, col2: { visible: true }, col3: { visible: true }, col4: { visible: false } }
      Columns.calculateVisibleCount()
      expect(Columns.visibleCount).toBe 2

    it "$broadcasts the updated visible count to $rootScope", inject ($rootScope) ->
      spyOn($rootScope, "$broadcast")
      Columns.calculateVisibleCount()
      expect($rootScope.$broadcast).toHaveBeenCalled()
