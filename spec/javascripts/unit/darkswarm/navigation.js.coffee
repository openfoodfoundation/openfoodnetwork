describe 'Navigation service', ->
  Navigation = null
  
  beforeEach ->
    module 'Darkswarm'
    inject ($injector)->
      Navigation = $injector.get("Navigation")

  it "caches the path provided", ->
    Navigation.navigate "/foo"
    expect(Navigation.path).toEqual "/foo"

  it "defaults to the first path in the list", ->
    Navigation.paths = ["/test", "/bar"]
    Navigation.navigate()
    expect(Navigation.path).toEqual "/test"
