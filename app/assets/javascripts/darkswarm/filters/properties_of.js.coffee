Darkswarm.filter 'propertiesOf', ->
  (objects)->
    properties = {}
    for object in objects
      for property in object.properties
        properties[property.id] = property
    properties
