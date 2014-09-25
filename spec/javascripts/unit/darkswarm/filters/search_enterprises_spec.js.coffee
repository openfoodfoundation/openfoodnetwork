describe 'filtering Enterprises', ->
  filter = null
  searchEnterprises = null
  enterprises = [{
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
      searchEnterprises = $filter('enterprises')

  it 'has a enterprise filter', ->
    expect(filter('enterprises')).not.toBeNull()

  it "filters by name", ->
    expect(searchEnterprises(enterprises, 'donkeys').length).toEqual 1

  it "is case insensitive", ->
    expect(searchEnterprises(enterprises, 'DONKEYS').length).toEqual 1

  it "filters by state", ->
    expect(searchEnterprises(enterprises, 'kansas').length).toEqual 1

  it "filters by zipcode", ->
    expect(searchEnterprises(enterprises, 'cats').length).toEqual 1

  it "gives all enterprises when no argument is specified", ->
    expect(searchEnterprises(enterprises, '').length).toEqual 2

  it "does not filter by anything else", ->
    expect(searchEnterprises(enterprises, 'roger').length).toEqual 0
