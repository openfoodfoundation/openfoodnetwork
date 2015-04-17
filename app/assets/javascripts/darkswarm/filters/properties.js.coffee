Darkswarm.filter 'properties', ()->
  # Filter anything that responds to object.properties
  (objects, ids) ->
    objects ||= []
    ids ?= []
    if ids.length == 0
      # No properties selected, pass all objects through.
      objects
    else
      objects.filter (obj)->
        properties = obj.properties
        # Combine object properties with supplied properties, if they exist.
        # properties = properties.concat obj.supplied_properties if obj.supplied_properties
        # Match property array.
        properties.some (property)->
          property.id in ids
