angular.module('Darkswarm').factory 'MapCentreCalculator', (Enterprises, openStreetMapConfig) ->
  new class MapCentreCalculator
    # The outermost 1% of enterprises on each side are left out when finding the
    # core of the network. Any enterprise within half the core's extent of it is
    # then shown, so remote producers stay on the map while a few mis-geocoded
    # addresses can't stretch the initial view across continents. Below 20
    # enterprises we can't tell an outlier from a sparse network, so keep them all.
    OUTLIER_SHARE = 0.01
    NEARBY_SHARE = 0.5
    MINIMUM_ENTERPRISES_TO_TRIM = 20

    initialBounds: =>
      enterprises = Enterprises.geocodedEnterprises()
      return null if enterprises.length == 0

      if enterprises.length >= MINIMUM_ENTERPRISES_TO_TRIM
        latitudeRange = @_nearbyRange(@_trimmedAngles("latitude", enterprises))
        longitudeRange = @_nearbyRange(@_trimmedAngles("longitude", enterprises))
        enterprises = enterprises.filter (enterprise) ->
          latitudeRange[0] <= enterprise.latitude <= latitudeRange[1] &&
            longitudeRange[0] <= enterprise.longitude <= longitudeRange[1]

      latitudes = (enterprise.latitude for enterprise in enterprises)
      longitudes = (enterprise.longitude for enterprise in enterprises)

      [
        [Math.min(latitudes...), Math.min(longitudes...)],
        [Math.max(latitudes...), Math.max(longitudes...)]
      ]

    defaultCentre: =>
      [
        openStreetMapConfig.open_street_map_default_latitude,
        openStreetMapConfig.open_street_map_default_longitude
      ]

    _trimmedAngles: (angleName, coordinates) =>
      angles = (coordinate[angleName] for coordinate in coordinates).sort (a, b) -> a - b
      trim = Math.ceil(angles.length * OUTLIER_SHARE)
      angles.slice(trim, angles.length - trim)

    _nearbyRange: (angles) =>
      minimum = angles[0]
      maximum = angles[angles.length - 1]
      margin = (maximum - minimum) * NEARBY_SHARE
      [minimum - margin, maximum + margin]
