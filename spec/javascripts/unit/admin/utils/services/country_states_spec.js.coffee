describe "CountryStates service", ->
  countryStates = null

  states_in_spain = [{id: 55, name: "CAT", abbr: "CAT"}]
  states_in_portugal = [{id: 55, name: "ACT", abbr: "ACT"}, {id: 5, name: "BFT", abbr: "BFT"}]
  availableCountries = [
    {id: 9, name: "Australia", states: []},
    {id: 119, name: "Spain", states: states_in_spain},
    {id: 19, name: "Portugal", states: states_in_portugal}
  ]

  beforeEach ->
    module('admin.utils')
    inject (CountryStates) ->
      countryStates = CountryStates

  describe "statesFor", ->
    it "returns empty array for nil country id", ->
      expect(countryStates.statesFor(availableCountries, null)).toEqual []

    it "returns empty array for country id not in availableCountries", ->
      expect(countryStates.statesFor(availableCountries, 10)).toEqual []

    it "returns empty array for country id in availableCountries but without states", ->
      expect(countryStates.statesFor(availableCountries, 9)).toEqual []

    it "returns states for country id in availableCountries with states", ->
      expect(countryStates.statesFor(availableCountries, 119)).toEqual states_in_spain

    it "returns empty array for country id (11) in availableCountries but only as part of other country id (119)", ->
      expect(countryStates.statesFor(availableCountries, 11)).toEqual []

    it "returns states for country id (19) in availableCountries with states even if other country ids contain the requested id (119)", ->
      expect(countryStates.statesFor(availableCountries, 19)).toEqual states_in_portugal
