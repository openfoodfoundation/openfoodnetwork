'use strict'

angular.module('store').
  factory('CartFactory', ['$resource', '$window', '$http', ($resource, $window, $http) ->
    Cart = $resource '/open_food_network/cart/:cart_id.json', {},
      { 'show':  { method: 'GET'} }

    load: (id, callback) ->
      Cart.show {cart_id: id}, (cart) ->
        callback(cart)
    ])
