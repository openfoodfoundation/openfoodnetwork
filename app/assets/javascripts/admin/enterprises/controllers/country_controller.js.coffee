# Used in enterprise new and edit forms to reset the state when the country is changed
angular.module("admin.enterprises").controller 'countryCtrl', ($scope, $timeout, availableCountries) ->
  $scope.address_type = "address"
  $scope.countries = availableCountries

  $scope.countriesById = $scope.countries.reduce (obj, country) ->
    obj[country.id] = country
    obj
  , {}

  $timeout ->
    $scope.$watch 'Enterprise.' + $scope.address_type + '.country_id', (newID, oldID) ->
      $scope.clearState() unless $scope.addressStateMatchesCountry()

  $scope.clearState = ->
    $scope.Enterprise[$scope.address_type].state_id = null

  $scope.addressStateMatchesCountry = ->
    $scope.countriesById[$scope.Enterprise[$scope.address_type].country_id].states.some (state) ->
      state.id == $scope.Enterprise[$scope.address_type].state_id
