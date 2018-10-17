angular.module("admin.utils").factory "CountryStates", ($filter) ->
  new class CountryStates

    statesFor: (countries, country_id) ->
      return [] unless country_id
      country = $filter('filter')(countries, {id: parseInt(country_id)}, true)[0]
      return [] unless country
      country.states

    addressStateMatchesCountryStates: (countryStates, stateId) ->
      countryStates.some (state) -> state.id == stateId
