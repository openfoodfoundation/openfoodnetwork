describe "Sidebar", ->
  location = null
  Sidebar = null
  Navigation = null

  beforeEach ->
    module("Darkswarm")
    inject (_Sidebar_, $location, _Navigation_) ->
      Sidebar = _Sidebar_
      Navigation = _Navigation_
      location = $location
      Sidebar.paths = ["/test", "/frogs"]


  it 'is active when a location in paths is set', ->
    spyOn(location, "path").and.returnValue "/test"
    expect(Sidebar.active()).toEqual true

  it 'is inactive if location is set', ->
    spyOn(location, "path").and.returnValue null
    expect(Sidebar.active()).toEqual false

  describe "Toggling on/off", ->
    it 'toggles the current sidebar path', ->
      expect(Sidebar.active()).toEqual false
      Navigation.path = "/frogs"
      Sidebar.toggle()
      expect(Sidebar.active()).toEqual true

    it 'If current navigation path is not in the sidebar, it toggles the first sidebar path', ->
      Navigation.path = "/donkeys"
      spyOn(Navigation, 'navigate')
      Sidebar.toggle()
      expect(Navigation.navigate).toHaveBeenCalledWith("/test")
