describe "Properties service", ->
  Properties = null
  properties = [
    {id: 1, name: "Property1"}
    {id: 2, name: "Property2"}
  ]

  beforeEach ->
    module('Darkswarm')
    angular.module('Darkswarm').value 'properties', properties

    inject ($injector)->
      Properties = $injector.get("Properties")

  it "caches properties in an id-referenced hash", ->
    expect(Properties.properties_by_id[1]).toBe properties[0]
