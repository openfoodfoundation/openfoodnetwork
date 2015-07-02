describe "Enterprises service", ->
  Enterprises = null
  CurrentHubMock = {}
  Geo =
    OK: 'ok'
    succeed: true
    geocode: (query, callback) ->
      if @succeed
        results = [{geometry: {location: "location"}}]
        callback(results, @OK)
      else
        callback(results, 'Oops')
    distanceBetween: (locatable, location) ->
      123

  taxons = [
    {id: 1, name: "test"}
  ]
  enterprises = [
    {id: 1, visible: true, category: "hub", producers: [{id: 5}], taxons: [{id: 1}]},
    {id: 2, visible: true, category: "hub", producers: [{id: 6}]}
    {id: 3, visible: true, category: "hub_profile"}
    {id: 4, visible: false, category: "hub", producers: [{id: 7}]}
    {id: 5, visible: true, category: "producer_hub", hubs: [{id: 1}]},
    {id: 6, visible: true, category: "producer_shop", hubs: [{id: 2}]},
    {id: 7, visible: true, category: "producer", hubs: [{id: 2}]}
    {id: 8, visible: false, category: "producer", hubs: [{id: 2}]}
  ]
  H1: 0
  beforeEach ->
    module 'Darkswarm'
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock
      $provide.value "Geo", Geo
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
    expect(Enterprises.enterprises_by_id["1"].producers[0]).toBe enterprises[4]
    expect(Enterprises.enterprises_by_id["5"].hubs[0]).toBe enterprises[0]

  it "dereferences taxons", ->
    expect(Enterprises.enterprises[0].taxons[0]).toBe taxons[0]

  it "filters Enterprise.hubs into a new array", ->
    expect(Enterprises.hubs[0]).toBe Enterprises.enterprises[0]
    # Because the $filter is a new sorted array
    # We check to see the objects in both arrays are still the same
    Enterprises.enterprises[0].active = false
    expect(Enterprises.hubs[0].active).toBe false

  it "filters Enterprises.producers into a new array", ->
    expect(Enterprises.producers[0]).toBe Enterprises.enterprises[4]
    Enterprises.enterprises[4].active = false
    expect(Enterprises.producers[0].active).toBe false

  it "only includes visible enterprises in hubs array", ->
    expect(Enterprises.hubs).toContain Enterprises.enterprises[0]
    expect(Enterprises.hubs).not.toContain Enterprises.enterprises[3]

  it "only includes visible enterprises in producers array", ->
    expect(Enterprises.producers).toContain Enterprises.enterprises[4]
    expect(Enterprises.producers).not.toContain Enterprises.enterprises[7]

  it "includes hub, hub_profile, producer_hub and, producer_shop enterprises in hubs array", ->
    expect(Enterprises.hubs).toContain Enterprises.enterprises[0]
    expect(Enterprises.hubs).toContain Enterprises.enterprises[2]
    expect(Enterprises.hubs).toContain Enterprises.enterprises[4]
    expect(Enterprises.hubs).toContain Enterprises.enterprises[5]

  it "includes producer_hub, producer_shop and producer enterprises in producers array", ->
    expect(Enterprises.producers).toContain Enterprises.enterprises[4]
    expect(Enterprises.producers).toContain Enterprises.enterprises[5]
    expect(Enterprises.producers).toContain Enterprises.enterprises[6]

  describe "updating distance of enterprises from a location", ->
    it "calculates the distance when a query is provided", ->
      spyOn(Enterprises, "calculateDistance")
      Enterprises.updateDistance "asdf"
      expect(Enterprises.calculateDistance).toHaveBeenCalledWith("asdf")

    it "resets the distance when query is null", ->
      spyOn(Enterprises, "resetDistance")
      Enterprises.updateDistance null
      expect(Enterprises.resetDistance).toHaveBeenCalled()

    it "resets the distance when query is blank", ->
      spyOn(Enterprises, "resetDistance")
      Enterprises.updateDistance ""
      expect(Enterprises.resetDistance).toHaveBeenCalled()

  describe "calculating the distance of enterprises from a location", ->
    beforeEach ->
      spyOn(Enterprises, "setDistanceFrom")

    it "calculates distance for all enterprises when geocoding succeeds", ->
      Geo.succeed = true
      Enterprises.calculateDistance('query')
      expect(Enterprises.setDistanceFrom).toHaveBeenCalledWith("location")

    it "resets distance when geocoding fails", ->
      Geo.succeed = false
      spyOn(Enterprises, "resetDistance")
      Enterprises.calculateDistance('query')
      expect(Enterprises.setDistanceFrom).not.toHaveBeenCalled()
      expect(Enterprises.resetDistance).toHaveBeenCalled()

  describe "setting the distance of each enterprise from a central location", ->
    it "sets the distances", ->
      Enterprises.setDistanceFrom 'location'
      for e in Enterprises.enterprises
        expect(e.distance).toEqual 123

  describe "resetting the distance measurement of all enterprises", ->
    beforeEach ->
      e.distance = 123 for e in Enterprises.enterprises

    it "resets the distance", ->
      Enterprises.resetDistance()
      for e in Enterprises.enterprises
        expect(e.distance).toBeNull()