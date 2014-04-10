describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  order = null

  beforeEach ->
    module("Darkswarm")
    order = {
      submit: ->
    } 
    inject ($controller, $rootScope) ->
      scope = $rootScope.$new() 
      ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: order}

  it "defaults the user accordion to visible", ->
    expect(scope.accordion.user).toEqual true
  
  it "delegates to the service on submit", ->
    event = {
      preventDefault: ->
    }
    spyOn(order, "submit")
    scope.purchase(event)
    expect(order.submit).toHaveBeenCalled()

  it "finds a field by path", ->
    scope.checkout = 
      path: "test"
    expect(scope.field('path')).toEqual "test"

  it "tests validity", ->
    scope.checkout =
      path: 
        $dirty: true
        $invalid: true
    expect(scope.fieldValid('path')).toEqual false

  it "returns errors by path", ->
    scope.checkout =
      path: 
        $error: 
          email: true
          required: true
    expect(scope.fieldErrors('path')).toEqual ["must be email address", "must not be blank"].join ", "
