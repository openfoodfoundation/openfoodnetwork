describe "Columns service", ->
  Columns = null

  beforeEach ->
    module 'admin.indexUtils'

    inject (_Columns_) ->
      Columns = _Columns_

    Columns.columns = ["something"]

  describe "setting columns", ->
    it "sets resets @columns and copies each column of the provided object across", ->
      Columns.setColumns({ name: { visible: true } })
      expect(Columns.columns).toEqual { name: { visible: true } }
