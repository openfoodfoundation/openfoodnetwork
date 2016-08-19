Darkswarm.filter 'properties', ->
  # Filter anything that responds to object.supplied_properties
  (objects, ids) ->
    objects ||= []
    ids ?= []
    if ids.length == 0
      # No properties selected, pass all objects through.
      objects
    else
      objects.filter (obj) ->
        obj.supplied_properties.some (property) ->
          property.id in ids
