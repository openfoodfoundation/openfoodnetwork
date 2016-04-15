angular.module("admin.shippingMethods")
  .factory "ShippingMethods", (shippingMethods) ->
    new class ShippingMethods
      shippingMethods: shippingMethods

      findByID: (id) ->
        for shippingMethod in @shippingMethods
          return shippingMethod if shippingMethod.id is id
