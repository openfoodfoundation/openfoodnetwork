angular.module("admin.enterprises").controller 'countryCtrl', ($scope, availableCountries) ->

  $scope.countries = availableCountries

  $scope.countriesById = $scope.countries.reduce (obj, country) ->
    obj[country.id] = country
    obj
  , {}

  $scope.countryOnChange = (stateSelectElemId) ->
    $scope.clearState() unless $scope.addressStateMatchesCountry()
    $scope.refreshStateSelector(stateSelectElemId)

  $scope.clearState = ->
    $scope.enterprise_address_attributes_state = {}

  $scope.addressStateMatchesCountry = ->
    $scope.countriesById[$scope.enterprise_address_attributes_country.id].states.some (state) -> state.id == $scope.enterprise_address_attributes_state?.id

  $scope.refreshStateSelector = (stateSelectElemId) ->
  	# workaround select2 (using jQuery and setTimeout) to force a refresh of the selected value
    setTimeout ->
      selectedState = jQuery('#' + stateSelectElemId)
      jQuery('#' + stateSelectElemId).select2("val", selectedState)
    , 500