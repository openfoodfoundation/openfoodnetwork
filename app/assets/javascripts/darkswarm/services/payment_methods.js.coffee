angular.module('Darkswarm').factory "PaymentMethods", (paymentMethods)->
  new class PaymentMethods
    payment_methods: paymentMethods
    payment_methods_by_id: {}
    constructor: ->
      for method in @payment_methods
        method.price = parseFloat(method.price)
        @payment_methods_by_id[method.id] = method

