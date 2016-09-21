Darkswarm.filter 'propertiesOf', ->
  (objects) ->
    properties = {}
    for object in objects
      if object.supplied_properties?
        for property in object.supplied_properties
          properties[property.id] = property
      else
        for property in object.properties
          properties[property.id] = property

    properties
