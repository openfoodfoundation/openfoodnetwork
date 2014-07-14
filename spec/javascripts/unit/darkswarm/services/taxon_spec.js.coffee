describe "Taxons service", ->
  Taxons = null
  taxons = [
    {id: 1, name: "test"}
    {id: 2, name: "Roger"}
  ]

  beforeEach ->
    module('Darkswarm')
    angular.module('Darkswarm').value 'taxons', taxons 

    inject ($injector)->
      Taxons = $injector.get("Taxons") 

  it "caches taxons in an id-referenced hash", ->
    expect(Taxons.taxons_by_id[1]).toBe taxons[0]
