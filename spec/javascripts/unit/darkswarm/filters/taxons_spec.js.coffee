describe 'filtering by taxons', ->
  filterByTaxons = null
  objects = [
    {
      taxons: []
      primary_taxon: 
        name: "frogs"
    }
    {
      taxons: [
        {name: "kittens"}
        {name: "puppies"}
      ]
    }
  ]


  beforeEach ->
    module 'Darkswarm'
    inject ($filter) ->
      filterByTaxons = $filter('taxons')

  it "filters by primary taxon", ->
    expect(filterByTaxons(objects, "frogs")[0]).toBe objects[0]

  it "filters by taxons", ->
    expect(filterByTaxons(objects, "kittens")[0]).toBe objects[1]
