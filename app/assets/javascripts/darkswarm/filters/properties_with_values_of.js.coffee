angular.module('Darkswarm').filter 'propertiesWithValuesOf', ->
  (objects)->
    propertiesWithValues = {}
    for object in objects
      for property in object.properties_with_values
        propertiesWithValues[property.id] = property
    propertiesWithValues
