describe "Hubs service", ->
  OfnMap = null
  CurrentHubMock = {}
  Geo = {}
  enterprises = [
    {
      id: 2
      active: false
      orders_close_at: new Date()
      type: "hub"
      visible: true
      latitude: 0
      longitude: 0
    }
    {
      id: 3
      active: false
      orders_close_at: new Date()
      type: "hub"
      visible: true
      latitude: null
      longitude: null
    }
  ]

  beforeEach ->
    module 'Darkswarm'
    angular.module('Darkswarm').value('enterprises', enterprises)
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock
      $provide.value "Geo", Geo
      null
    inject ($injector)->
      OfnMap = $injector.get("OfnMap")

  it "builds MapMarkers from enterprises", ->
    expect(OfnMap.enterprises[0].id).toBe enterprises[0].id

  it "excludes enterprises without latitude or longitude", ->
    expect(OfnMap.enterprises.map (e) -> e.id).not.toContain enterprises[1].id
