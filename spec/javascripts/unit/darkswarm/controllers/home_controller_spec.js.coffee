describe "HomeCtrl", ->
  ctrl = null
  scope = null

  beforeEach ->
    module 'Darkswarm'
    scope = {}

    inject ($controller) ->
      ctrl = $controller 'HomeCtrl', {$scope: scope}

  it "starts with the brand story contracted", ->
    expect(scope.brandStoryExpanded).toBe false

  it "toggles the brand story", ->
    scope.toggleBrandStory()
    expect(scope.brandStoryExpanded).toBe true
    scope.toggleBrandStory()
    expect(scope.brandStoryExpanded).toBe false
