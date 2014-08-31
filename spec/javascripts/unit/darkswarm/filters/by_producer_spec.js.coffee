describe 'filtering by producer', ->
  filterByProducer = null
  objects = [
    {
      producer: 
        id: 1 
    }
    {
      producer: 
        id: 2 
    }
  ]

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filterByProducer = $filter('byProducer')
  
  it "filters by producer", ->
    expect(filterByProducer(objects, 1)[0]).toBe objects[0]
    expect(filterByProducer(objects, 2)[0]).toBe objects[1]
