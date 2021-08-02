angular.module('Darkswarm').controller "CountryCtrl", ($scope, availableCountries) ->

  $scope.countries = availableCountries

  $scope.countriesById = $scope.countries.reduce (obj, country) ->
    obj[country.id] = country
    obj
  , {}
