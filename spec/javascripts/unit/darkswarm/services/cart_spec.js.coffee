describe 'Cart service', ->
  Cart = null
  orders = []

  beforeEach ->
    module 'Darkswarm'
    angular.module('Darkswarm').value('order', orders)
    inject ($injector)->
      Cart =  $injector.get("Cart")
