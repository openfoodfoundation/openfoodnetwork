angular.module('Darkswarm').factory 'Dereferencer', ->
  new class Dereferencer
    dereference: (array, data) ->
      @dereference_from(array, array, data)

    dereference_from: (source, target, data) ->
      unreferenced = []
      if source && target
        for object, i in source
          # skip empty entries in sparse array
          continue unless source.hasOwnProperty(i)
          key = object?.id
          if data.hasOwnProperty(key)
            target[i] = data[key]
          else
            unreferenced[i] = object
      unreferenced
