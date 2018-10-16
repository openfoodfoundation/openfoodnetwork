angular.module("ofn.admin").factory "CountryStates", ($filter) ->
  new class CountryStates

    statesFor: (countries, country_id) ->
      return [] unless country_id
      country = $filter('filter')(countries, {id: country_id}, true)[0]
      return [] unless country
      country.states
