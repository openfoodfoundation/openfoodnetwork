angular.module("admin.enterprises")
  .factory "EnterpriseShippingMethods", (Enterprise, ShippingMethods) ->
    new class EnterpriseShippingMethods
      shippingMethods: ShippingMethods.shippingMethods

      constructor: ->
        for shipping_method in @shippingMethods
          shipping_method.selected = shipping_method.id in Enterprise.enterprise.shipping_method_ids

      displayColor: ->
        if @shippingMethods.length > 0 && @selectedCount() > 0
          "blue"
        else
          "red"

      selectedCount: ->
        @shippingMethods.reduce (count, shipping_method) ->
          count++ if shipping_method.selected
          count
        , 0
