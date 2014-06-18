describe "Enterprises service", ->
  Enterprises = null
  enterprises = [
    {id: 1, type: "hub"},
    {id: 2, type: "producer"}
  ]
  beforeEach ->
    module 'Darkswarm'
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
