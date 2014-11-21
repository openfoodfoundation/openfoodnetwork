describe "indexer", ->
  Indexer = null

  beforeEach ->
    module "ofn.admin"

  beforeEach inject (_Indexer_) ->
    Indexer = _Indexer_

  it "indexes an array of objects by id", ->
    objects = [{id: 1, name: 'one'}, {id: 2, name: 'two'}]
    index = Indexer.index objects
    expect(index).toEqual({1: {id: 1, name: 'one'}, 2: {id: 2, name: 'two'}})
