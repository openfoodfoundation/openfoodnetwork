angular.module('Darkswarm').directive 'ofnOpenStreetMap', ($window, MapCentreCalculator, Enterprises, EnterpriseModal, availableCountries, openStreetMapConfig) ->
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

    # Remove event handlers on $destroy
    scope.$on "$destroy", ->
      markers.forEach(marker_element) ->
        marker_element.off("click")

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
      map.setView([MapCentreCalculator.initialLatitude(), MapCentreCalculator.initialLongitude()], zoomLevel)

    displayEnterprises = ->
      for enterprise in Enterprises.geocodedEnterprises()
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
      if Enterprises.geocodedEnterprises().length == 0
        disableSearchField()

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
