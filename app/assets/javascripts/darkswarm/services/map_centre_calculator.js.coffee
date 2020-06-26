Darkswarm.factory 'MapCentreCalculator', ->
  new class MapCentreCalculator
    calculate_latitude: (coordinates) =>
      @_calculate("latitude", coordinates)

    calculate_longitude: (coordinates) =>
      @_calculate("longitude", coordinates)

    _calculate: (angleName, coordinates) =>
      positiveAngles = []
      negativeAngles = []
      angles = []

      for coordinate in coordinates
        angles.push(coordinate[angleName])
        if coordinate[angleName] > 0
          positiveAngles.push(coordinate[angleName])
        else
          negativeAngles.push(coordinate[angleName])

      minimumAngle = Math.min.apply(null, angles)
      maximumAngle = Math.max.apply(null, angles)

      distanceBetweenMinimumAndMaximum = if maximumAngle > minimumAngle
        maximumAngle - minimumAngle
      else
        minimumAngle - maximumAngle

      minimumAngle + (distanceBetweenMinimumAndMaximum / 2)
