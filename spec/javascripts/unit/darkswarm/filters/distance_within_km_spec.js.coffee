describe "filtering enterprises to those within a certain radius", ->
  filter = null
  enterprises = [
    {distance: 25000}
    {distance: 75000}
  ]

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filter = $filter('distanceWithinKm')

  it "filters to those enterprises within a distance", ->
    expect(filter(enterprises, 50)).toEqual [enterprises[0]]

  it "returns empty array when enterprises array is null", ->
    expect(filter(null, 50)).toEqual []
