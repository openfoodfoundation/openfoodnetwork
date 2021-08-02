angular.module('Darkswarm').filter 'properties', ->
  # Filter anything that responds to object.supplied_properties
  (objects, ids, source) ->
    objects ||= []
    ids ?= []

    source ||= 'properties'
    return [] unless source in ['properties', 'supplied_properties', 'distributed_properties']

    if ids.length == 0
      # No properties selected, pass all objects through.
      objects
    else
      objects.filter (obj) ->
        properties = obj[source]
        properties.some (property) ->
          property.id in ids
