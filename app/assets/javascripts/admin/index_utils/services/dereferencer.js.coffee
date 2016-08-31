angular.module("admin.indexUtils").factory 'Dereferencer', ->
  new class Dereferencer
    dereference: (array, data)->
      if array
        for object, i in array
          match = data[object.id]
          array[i] = match if match?

    dereferenceAttr: (array, attr, data)->
      if array
        for object in array
          object[attr] = data[object[attr].id] unless object[attr] == null
