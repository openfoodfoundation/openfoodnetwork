angular.module('Darkswarm').filter 'propertiesOf', ->
  (objects, source) ->
    source ||= 'properties'
    return {} unless source in ['properties', 'supplied_properties', 'distributed_properties']

    properties = {}
    for object in objects
      if object[source]?
        for property in object[source]
          properties[property.id] = property

    properties
