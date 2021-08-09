angular.module('Darkswarm').factory "Properties", (properties)->
  new class Properties
    # Populate ProductProperties.properties from json in page.
    properties: properties
    properties_by_id: {}
    constructor: ->
      # Map properties to id/object pairs for lookup.
      for property in @properties
        @properties_by_id[property.id] = property
