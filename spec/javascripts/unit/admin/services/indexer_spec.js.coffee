describe "indexer", ->
  Indexer = null

  beforeEach ->
    module "admin.indexUtils"

  beforeEach inject (_Indexer_) ->
    Indexer = _Indexer_

  it "indexes an array of objects by id", ->
    objects = [{id: 1, name: 'one'}, {id: 2, name: 'two'}]
    index = Indexer.index objects
    expect(index).toEqual({1: {id: 1, name: 'one'}, 2: {id: 2, name: 'two'}})

  it "indexes an array of objects by another field", ->
    objects = [{widget_id: 1, name: 'one'}, {widget_id: 2, name: 'two'}]
    index = Indexer.index objects, 'widget_id'
    expect(index).toEqual({1: {widget_id: 1, name: 'one'}, 2: {widget_id: 2, name: 'two'}})

  it "returns an object, not an array", ->
    index = Indexer.index []
    expect(index.constructor).not.toEqual(Array)
