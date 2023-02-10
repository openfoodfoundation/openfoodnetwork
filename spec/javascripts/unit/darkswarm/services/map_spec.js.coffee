describe "Hubs service", ->
  OfnMap = null
  CurrentHubMock = {}
  GmapsGeo = {}
  enterprises = [
    {
      id: 2
      active: false
      icon_font: 'abc'
      name: 'BugSpray'
      orders_close_at: new Date()
      type: "hub"
      visible: true
      latitude: 0
      longitude: 0
    }
    {
      id: 3
      active: false
      icon_font: 'def'
      name: 'Toothbrush'
      orders_close_at: new Date()
      type: "hub"
      visible: true
      latitude: 100
      longitude: 200
    }
    {
      id: 4
      active: false
      icon_font: 'ghi'
      name: 'Covidness'
      orders_close_at: new Date()
      type: "hub"
      visible: true
      latitude: null
      longitude: null
    }
    {
      id: 5
      active: false
      icon_font: 'jkl'
      name: 'Toothbrush for kids'
      orders_close_at: new Date()
      type: "hub"
      visible: true
      latitude: 100
      longitude: 200
    }
  ]

  beforeEach ->
    module 'Darkswarm'
    angular.module('Darkswarm').value('enterprises', enterprises)
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock
      $provide.value "GmapsGeo", GmapsGeo
      $provide.value "taxons", []
      null
    inject ($injector)->
      OfnMap = $injector.get("OfnMap")

  it "builds MapMarkers from enterprises", ->
    expect(OfnMap.enterprises[0].id[0]).toBe enterprises[0].id

  it "excludes enterprises without latitude or longitude", ->
    expect(OfnMap.enterprises.map (e) -> e.id).not.toContain [enterprises[2].id]

  it "the MapMarkers will a field for enterprises", ->
    enterprise = enterprises[0]
    expect(OfnMap.enterprises[0].enterprises[enterprise.id]).toEqual { id: enterprise.id, name: enterprise.name, icon: enterprise.icon_font }

  it "the MapMarkers will bunch up enterprises with the same coordinates", ->
    enterprise1 = enterprises[1]
    enterprise2 = enterprises[3]
    hash = {}
    hash[enterprise1.id] = { id: enterprise1.id, name: enterprise1.name, icon: enterprise1.icon_font }
    hash[enterprise2.id] = { id: enterprise2.id, name: enterprise2.name, icon: enterprise2.icon_font }
    expect(OfnMap.enterprises[2].enterprises).toEqual hash
