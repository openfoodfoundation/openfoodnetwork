describe 'Navigation service', ->
  Navigation = null
  
  beforeEach ->
    module 'Darkswarm'
    inject ($injector)->
      Navigation = $injector.get("Navigation")

  it "caches the path provided", ->
    Navigation.navigate "/foo"
    expect(Navigation.path).toEqual "/foo"
