describe 'filtering by active', ->
  filterByActive = null
  objects = [
    {active: true}
    {active: false}
  ]


  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filterByActive = $filter('active')

  it "filters to active", ->
    expect(filterByActive(objects, {closed: false, open: true})[0]).toBe objects[0]

  it "filters to inactive", ->
    expect(filterByActive(objects, {closed: true, open: false})[0]).toBe objects[1]

  it "doesn't filter if needed", ->
    expect(filterByActive(objects, {closed: false, open: false})).toBe objects

  it "filters to all", ->
    expect(filterByActive(objects, {closed: true, open: true})).toBe objects
