Darkswarm.filter "printArray", ->
  (array, attr = 'name')->
    array ?= []
    array.map (a)->
      a[attr]
    .join(", ")
