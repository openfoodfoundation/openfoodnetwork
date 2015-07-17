describe "Groups service", ->
  Groups = null
  Enterprises = null
  CurrentHubMock = {}
  Geo = {}
  groups = [{
    id: 1
    name: "Test Group"
    enterprises: [
      {id: 1},
      {id: 2}
    ]
  }]
  enterprises = [
    {id: 1, name: "Test 1", groups: [{id: 1}]},
    {id: 2, name: "Test 2", groups: [{id: 1}]}
  ]

  beforeEach ->
    module 'Darkswarm'
    angular.module('Darkswarm').value('groups', groups)
    angular.module('Darkswarm').value('enterprises', enterprises)
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock
      $provide.value "Geo", Geo
      null
    inject (_Groups_, _Enterprises_)->
      Groups = _Groups_
      Enterprises = _Enterprises_

  it "dereferences group enterprises", ->
    expect(Groups.groups[0].enterprises[0]).toBe enterprises[0]

  it "dereferences enterprise groups", ->
    expect(Enterprises.enterprises[0].groups[0]).toBe groups[0]
