describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  order = null 

  beforeEach ->
    module("Darkswarm")
    order = {} 
    inject ($controller) ->
      scope = {}
      ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: order}
