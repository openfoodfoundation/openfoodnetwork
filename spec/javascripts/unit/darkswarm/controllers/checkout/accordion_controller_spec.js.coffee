describe "AccordionCtrl", ->
  ctrl = null
  scope = scope

  beforeEach ->
    module "Darkswarm"
    localStorage.clear()
    inject ($controller, $rootScope) ->
      scope = $rootScope.$new() 
      scope.order =
        id: 129
      ctrl = $controller 'AccordionCtrl', {$scope: scope}

  it "defaults the details accordion to visible", ->
    expect(scope.accordion.details).toEqual true

  it "changes accordion", ->
    scope.show "shipping"
    expect(scope.accordion["shipping"]).toEqual true
