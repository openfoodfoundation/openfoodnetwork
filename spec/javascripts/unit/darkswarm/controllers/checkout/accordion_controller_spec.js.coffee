describe "AccordionCtrl", ->
  ctrl = null
  scope = null
  CurrentHubMock = 
    id: 1

  beforeEach ->
    module "Darkswarm"
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock 
      null
    localStorage.clear()

  describe "loading incomplete form", ->
    beforeEach ->
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

  describe "loading complete form", ->
    beforeEach ->
      inject ($controller, $rootScope) ->
        scope = $rootScope.$new() 
        scope.checkout =
          $valid: true
        scope.order =
          id: 129
        ctrl = $controller 'AccordionCtrl', {$scope: scope}
