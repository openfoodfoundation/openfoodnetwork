# Used in enterprise new and edit forms to reset the state when the country is changed
angular.module("admin.enterprises").controller 'countryCtrl', ($scope, availableCountries) ->
  $scope.countries = availableCountries

  $scope.countriesById = $scope.countries.reduce (obj, country) ->
    obj[country.id] = country
    obj
  , {}

  $scope.$watch 'Enterprise.address.country_id', (newID, oldID) ->
    $scope.clearState() unless $scope.addressStateMatchesCountry()

  $scope.clearState = ->
    $scope.Enterprise.address.state_id = null

  $scope.addressStateMatchesCountry = ->
    $scope.countriesById[$scope.Enterprise.address.country_id].states.some (state) ->
      state.id == $scope.Enterprise.address.state_id
