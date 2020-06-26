Darkswarm.directive 'ofnOpenStreetMap', ($window, Enterprises, EnterpriseModal, availableCountries, openStreetMapConfig) ->
  restrict: 'E'
  replace: true
  scope: true
  template: "<div></div>"

  link: (scope, element, attrs, ctrl, transclude)->
    map = null
    markers = []
    enterpriseNames = []
    openStreetMapProviderName = openStreetMapConfig.open_street_map_provider_name
    openStreetMapProviderOptions = JSON.parse(openStreetMapConfig.open_street_map_provider_options)

    average = (values) ->
      total = values.reduce (sum, value) ->
        sum = sum + value
      , 0
      total / values.length

    averageAngle = (angleName) ->
      positiveAngles = []
      negativeAngles = []
      for enterprise in Enterprises.enterprises
        if enterprise.latitude? && enterprise.longitude?
          if enterprise[angleName] > 0
            positiveAngles.push(enterprise[angleName])
          else
            negativeAngles.push(enterprise[angleName])

      averageNegativeAngle = average(negativeAngles)
      averagePositiveAngle = average(positiveAngles)

      if negativeAngles.length == 0
        averagePositiveAngle
      else if positiveAngles.length == 0
        averageNegativeAngle
      else if averagePositiveAngle > averageNegativeAngle
        averagePositiveAngle - averageNegativeAngle
      else
        averageNegativeAngle - averagePositiveAngle

    buildMarker = (enterprise, latlng, title) ->
      icon = L.icon
        iconUrl: enterprise.icon
      marker = L.marker latlng,
        draggable:   true,
        icon:        icon,
        riseOnHover: true,
        title:       title
      marker.on "click", ->
        EnterpriseModal.open enterprise
      marker

    enterpriseName = (enterprise) ->
      return enterprise.name + " (" + enterprise.address.address1 + ", " + enterprise.address.city + ", " + enterprise.address.state_name + ")";

    goToEnterprise = (selectedEnterpriseName) ->
      enterprise = Enterprises.enterprises.find (enterprise) ->
        enterpriseName(enterprise) == selectedEnterpriseName
      map.setView([enterprise.latitude, enterprise.longitude], 12)

    displayMap = ->
      setMapDimensions()
      zoomLevel = 6
      map = L.map('open-street-map')
      L.tileLayer.provider(openStreetMapProviderName, openStreetMapProviderOptions).addTo(map)
      map.setView([initialLatitude(), initialLongitude()], zoomLevel)

    displayEnterprises = ->
      for enterprise in geocodedEnterprises()
        marker = buildMarker(enterprise, { lat: enterprise.latitude, lng: enterprise.longitude }, enterprise.name).addTo(map)
        enterpriseNames.push(enterpriseName(enterprise))
        markers.push(marker)

    disableSearchField = () =>
      $('#open-street-map--search input').prop("disabled", true)

    displaySearchField = () ->
      new Autocomplete('#open-street-map--search',
        onSubmit: goToEnterprise
        search: searchEnterprises
      )
      overwriteInlinePositionRelativeToAbsoluteOnSearchField()
      if geocodedEnterprises().length == 0
        disableSearchField()

    geocodedEnterprises = () ->
      Enterprises.enterprises.filter (enterprise) ->
        enterprise.latitude? && enterprise.longitude?

    initialLatitude = () ->
      if geocodedEnterprises().length > 0
        averageAngle("latitude")
      else
        openStreetMapConfig.open_street_map_default_latitude || -37.4713077

    initialLongitude = () ->
      if geocodedEnterprises().length > 0
        averageAngle("longitude")
      else
        openStreetMapConfig.open_street_map_default_longitude || 144.7851531

    overwriteInlinePositionRelativeToAbsoluteOnSearchField = ->
      $('#open-street-map--search').css("position", "absolute")

    searchEnterprises = (input) ->
      if input.length < 1
        return []
      enterpriseNames.filter (country) ->
        country.toLowerCase().includes input.toLowerCase()

    setMapDimensions = ->
      height = $window.innerHeight - element.offset().top
      element.css "width", "100%"
      element.css "height", (height + "px")

    displayMap()
    displayEnterprises()
    displaySearchField()
