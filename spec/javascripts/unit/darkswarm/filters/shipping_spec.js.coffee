describe 'filtering by shipping method', ->
  filterByShippingMethod = null
  objects = [
    {
      delivery: true
      pickup: false
    }
    {
      delivery: false
      pickup: true
    }
  ]


  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filterByShippingMethod = $filter('shipping')

  it "filters to pickup", ->
    expect(filterByShippingMethod(objects, {pickup: true, delivery: false})[0]).toBe objects[1]

  it "filters to delivery", ->
    expect(filterByShippingMethod(objects, {pickup: false, delivery: true})[0]).toBe objects[0]

  it "filters to both", ->
    expect(filterByShippingMethod(objects, {pickup: true, delivery: true})).toBe objects

  it "filters to none", ->
    expect(filterByShippingMethod(objects, {pickup: false, delivery: false})).toBe objects

  it "filters to none with empty", ->
    expect(filterByShippingMethod(objects, {})).toBe objects
