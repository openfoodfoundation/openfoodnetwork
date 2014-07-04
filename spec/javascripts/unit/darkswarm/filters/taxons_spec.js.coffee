describe 'filtering by taxons', ->
  filterByTaxons = null
  objects = [
    {
      taxons: []
      supplied_taxons: []
      primary_taxon: 
        name: "frogs"
        id: 1
    }
    {
      taxons: [
        {name: "kittens", id: 2}
        {name: "puppies", id: 3}
      ]
      supplied_taxons: []
    }
  ]

  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filterByTaxons = $filter('taxons')

  it "filters by nothing", ->
    expect(filterByTaxons(objects, [])).toBe objects

  it "filters by primary taxon", ->
    expect(filterByTaxons(objects, [1])[0]).toBe objects[0]

  it "filters by taxons", ->
    expect(filterByTaxons(objects, [2])[0]).toBe objects[1]

  it "filters by multiple", ->
    expect(filterByTaxons(objects, [1, 2])[0]).toBe objects[0]
    expect(filterByTaxons(objects, [1, 2])[1]).toBe objects[1]


