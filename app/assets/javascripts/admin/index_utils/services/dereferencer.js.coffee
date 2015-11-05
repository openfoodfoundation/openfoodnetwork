angular.module("admin.indexUtils").factory 'Dereferencer', ->
  new class Dereferencer
    dereference: (array, data)->
      if array
        for object, i in array
          array[i] = data[object.id]

    dereferenceAttr: (array, attr, data)->
      if array
        for object in array
          console.log attr, object[attr].id if data[object[attr].id] == undefined
          object[attr] = data[object[attr].id]
