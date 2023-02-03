describe "DetailsCtrl", ->
  ctrl = null
  scope = null
  order = null
  CurrentUser = null

  beforeEach ->
    module("Darkswarm")
    inject ($controller, $rootScope) ->
      scope = $rootScope.$new() 
      CurrentUser = { id: 1 }
      ctrl = $controller 'DetailsCtrl', { $scope: scope, CurrentUser: CurrentUser }


  it "finds a field by path", ->
    scope.details = 
      path: "test"
    expect(scope.field('path')).toEqual "test"

  it "tests validity", ->
    scope.details =
      path: 
        $dirty: true
        $invalid: true
    expect(scope.fieldValid('path')).toEqual false

  it "returns errors by path", ->
    scope.Order = 
      errors: ->
    scope.details =
      path: 
        $error: 
          email: true
          required: true
    expect(scope.fieldErrors('path')).toEqual ["must be email address", "can't be blank"].join ", "


