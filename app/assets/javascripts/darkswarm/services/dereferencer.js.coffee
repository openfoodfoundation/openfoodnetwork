Darkswarm.factory 'Dereferencer', ->
  new class Dereferencer
    dereference: (array, data)->
      if array
        for object, i in array
          array[i] = data[object.id]
