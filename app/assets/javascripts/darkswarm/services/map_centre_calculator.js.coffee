angular.module('Darkswarm').factory 'MapCentreCalculator', (Enterprises, openStreetMapConfig) ->
  new class MapCentreCalculator

    initialLatitude: =>
      if Enterprises.geocodedEnterprises().length > 0
        @_calculate("latitude", Enterprises.geocodedEnterprises())
      else
        openStreetMapConfig.open_street_map_default_latitude

    initialLongitude: =>
      if Enterprises.geocodedEnterprises().length > 0
        @_calculate("longitude", Enterprises.geocodedEnterprises())
      else
        openStreetMapConfig.open_street_map_default_longitude

    _calculate: (angleName, coordinates) =>
      angles = []

      for coordinate in coordinates
        angles.push(coordinate[angleName])

      minimumAngle = Math.min.apply(null, angles)
      maximumAngle = Math.max.apply(null, angles)

      distanceBetweenMinimumAndMaximum = if maximumAngle > minimumAngle
        maximumAngle - minimumAngle
      else
        minimumAngle - maximumAngle

      minimumAngle + (distanceBetweenMinimumAndMaximum / 2)
