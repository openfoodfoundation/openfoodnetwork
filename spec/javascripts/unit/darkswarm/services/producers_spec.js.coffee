describe "Producers service", ->
  Producers = null
  Enterprises = null
  CurrentHubMock = 
    hub:
      id: 1
  enterprises = [
    {is_primary_producer: true}
  ]

  beforeEach ->
    module 'Darkswarm'
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock 
      null
    angular.module('Darkswarm').value('enterprises', enterprises) 
    inject ($injector)->
      Producers = $injector.get("Producers")

  it "delegates producers array to Enterprises", ->
    expect(Producers.producers[0]).toBe enterprises[0] 
