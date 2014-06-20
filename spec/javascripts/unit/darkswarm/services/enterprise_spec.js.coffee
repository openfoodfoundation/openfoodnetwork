describe "Enterprises service", ->
  Enterprises = null
  CurrentHubMock = {} 
  enterprises = [
    {id: 1, type: "hub", producers: [{id: 2}]},
    {id: 2, type: "producer", hubs: [{id: 1}]},
    {id: 3, type: "producer", hubs: [{id: 1}]}
  ]
  beforeEach ->
    module 'Darkswarm'
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock 
      null
    angular.module('Darkswarm').value('enterprises', enterprises) 

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
