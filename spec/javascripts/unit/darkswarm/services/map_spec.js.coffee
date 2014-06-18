describe "Hubs service", ->
  OfnMap = null
  enterprises = [
    {
      id: 2
      active: false
      orders_close_at: new Date()
      type: "hub"
    }
  ]

  beforeEach ->
    module 'Darkswarm'
    angular.module('Darkswarm').value('enterprises', enterprises) 
    inject ($injector)->
      OfnMap = $injector.get("OfnMap") 

  it "builds MapMarkers from enterprises", ->
    expect(OfnMap.enterprises[0].id).toBe enterprises[0].id
