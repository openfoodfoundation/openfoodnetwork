describe 'filtering Enterprises', ->
  filter = null
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
      filter = $filter('searchEnterprises')

  it "filters by name", ->
    expect(filter(enterprises, 'donkeys').length).toEqual 1

  it "is case insensitive", ->
    expect(filter(enterprises, 'DONKEYS').length).toEqual 1

  it "filters by state", ->
    expect(filter(enterprises, 'kansas').length).toEqual 1

  it "filters by zipcode", ->
    expect(filter(enterprises, 'cats').length).toEqual 1

  it "gives all enterprises when no argument is specified", ->
    expect(filter(enterprises, '').length).toEqual 2

  it "does not filter by anything else", ->
    expect(filter(enterprises, 'roger').length).toEqual 0
