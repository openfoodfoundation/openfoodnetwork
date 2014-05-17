describe 'filtering producers', ->
  filter = null 
  filterProducers = null
  producers = [{
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
      filterProducers = $filter('filterProducers')


  it 'has a producer filter', ->
    expect(filter('filterProducers')).not.toBeNull()
