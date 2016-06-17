Darkswarm.factory 'Dereferencer', ->
  new class Dereferencer
    dereference: (array, data) ->
      if array
        for object, i in array
          key = undefined
          key = object.id if object
          array[i] = data[key]
