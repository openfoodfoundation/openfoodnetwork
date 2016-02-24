# Convert an array of objects into a hash, indexed by the objects' ids
#
# producers = [{id: 1, name: 'one'}, {id: 2, name: 'two'}]
# Indexer.index producers
# -> {1: {id: 1, name: 'one'}, 2: {id: 2, name: 'two'}}

angular.module("admin.indexUtils").factory 'Indexer', ->
  new class Indexer
    index: (data, key='id') ->
      index = {}
      for e in data
        index[e[key]] = e
      index
