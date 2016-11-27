angular.module("admin.resources")
  .factory "PaymentMethods", ($injector) ->
    new class PaymentMethods
      paymentMethods: []
      byID: {}
      pristineByID: {}

      constructor: ->
        if $injector.has('paymentMethods')
          @load($injector.get('paymentMethods'))

      load: (paymentMethods) ->
        for paymentMethod in paymentMethods
          @paymentMethods.push paymentMethod
          @byID[paymentMethod.id] = paymentMethod
          @pristineByID[paymentMethod.id] = angular.copy(paymentMethod)
