Darkswarm.filter 'propertiesOf', ->
  (objects)->
    properties = {}
    for object in objects
      for property in object.supplied_properties
        properties[property.id] = property
    properties
