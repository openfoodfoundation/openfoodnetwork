describe 'filtering Hubs', ->
  filter = null
  filterHubs = null
  hubs = [{
    name: "frogs"
    other: "roger"
    address:
      zipcode: "cats"
      city: "cambridge"
      state: "kansas"
  }, {
    name: "donkeys"
    other: "roger"
    address:
      zipcode: ""
      city: "Wellington"
      state: "uzbekistan"
  }]

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filter = $filter
      filterHubs = $filter('filterHubs')

  it 'has a hub filter', ->
    expect(filter('filterHubs')).not.toBeNull()

  it "filters by name", ->
    expect(filterHubs(hubs, 'donkeys').length).toEqual 1

  it "is case insensitive", ->
    expect(filterHubs(hubs, 'DONKEYS').length).toEqual 1

  it "filters by state", ->
    expect(filterHubs(hubs, 'kansas').length).toEqual 1

  it "filters by zipcode", ->
    expect(filterHubs(hubs, 'cats').length).toEqual 1

  it "gives all hubs when no argument is specified", ->
    expect(filterHubs(hubs, '').length).toEqual 2

  it "does not filter by anything else", ->
    expect(filterHubs(hubs, 'roger').length).toEqual 0
