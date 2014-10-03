describe "Enterprises service", ->
  Enterprises = null
  CurrentHubMock = {}
  taxons = [
    {id: 1, name: "test"}
  ]
  enterprises = [
    {id: 1, visible: true, is_distributor: true, is_primary_producer: false, producers: [{id: 2}], taxons: [{id: 1}]},
    {id: 2, visible: true, is_distributor: false, is_primary_producer: true, hubs: [{id: 1}]},
    {id: 3, visible: true, is_distributor: false, is_primary_producer: true, hubs: [{id: 1}]}
  ]
  beforeEach ->
    module 'Darkswarm'
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock
      null
    angular.module('Darkswarm').value('enterprises', enterprises)
    angular.module('Darkswarm').value('taxons', taxons)

    inject ($injector)->
      Enterprises = $injector.get("Enterprises")

  it "stores enterprises as id/object pairs", ->
    expect(Enterprises.enterprises_by_id["1"]).toBe enterprises[0]
    expect(Enterprises.enterprises_by_id["2"]).toBe enterprises[1]

  it "stores enterprises as an array", ->
    expect(Enterprises.enterprises).toBe enterprises

  it "puts the same objects in enterprises and enterprises_by_id", ->
    expect(Enterprises.enterprises[0]).toBe Enterprises.enterprises_by_id["1"]

  it "dereferences references to other enterprises", ->
    expect(Enterprises.enterprises_by_id["1"].producers[0]).toBe enterprises[1]
    expect(Enterprises.enterprises_by_id["3"].hubs[0]).toBe enterprises[0]

  it "dereferences taxons", ->
    expect(Enterprises.enterprises[0].taxons[0]).toBe taxons[0]

  it "filters Enterprise.hubs into a new array", ->
    expect(Enterprises.hubs[0]).toBe Enterprises.enterprises[0]
    # Because the $filter is a new sorted array
    # We check to see the objects in both arrays are still the same
    Enterprises.enterprises[0].active = false
    expect(Enterprises.hubs[0].active).toBe false

  it "delegates producers array to Enterprises", ->
    expect(Enterprises.producers[0]).toBe enterprises[1]
