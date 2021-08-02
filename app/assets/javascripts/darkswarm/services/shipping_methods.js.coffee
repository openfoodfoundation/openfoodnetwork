angular.module('Darkswarm').factory "ShippingMethods", (shippingMethods)->
  new class ShippingMethods
    shipping_methods: shippingMethods
    shipping_methods_by_id: {}
    constructor: ->
      for method in @shipping_methods
        method.price = parseFloat(method.price)
        @shipping_methods_by_id[method.id] = method

