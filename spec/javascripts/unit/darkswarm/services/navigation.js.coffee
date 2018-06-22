describe 'Navigation service', ->
  Navigation = null
  window =
    location:
      href: null

  beforeEach ->
    module 'Darkswarm', ($provide) ->
      $provide.value "$window", window
      null
    inject ($injector)->
      Navigation = $injector.get("Navigation")


  it "caches the path provided", ->
    Navigation.navigate "/foo"
    expect(Navigation.path).toEqual "/foo"

  describe "redirecting", ->
    it "redirects to full URLs", ->
      Navigation.go "http://google.com"
      expect(window.location.href).toEqual "http://google.com"

    it "redirects to paths", ->
      Navigation.go "/woo/yeah"
      expect(window.location.href).toEqual "/woo/yeah"
