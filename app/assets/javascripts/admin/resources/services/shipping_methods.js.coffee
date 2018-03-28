angular.module("admin.resources")
  .factory "ShippingMethods", ($injector) ->
    new class ShippingMethods
      all: []
      byID: {}
      pristineByID: {}

      constructor: ->
        if $injector.has('shippingMethods')
          @load($injector.get('shippingMethods'))

      load: (shippingMethods) ->
        for shippingMethod in shippingMethods
          @all.push shippingMethod
          @byID[shippingMethod.id] = shippingMethod
          @pristineByID[shippingMethod.id] = angular.copy(shippingMethod)
