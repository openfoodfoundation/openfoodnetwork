angular.module("admin.paymentMethods")
  .factory "PaymentMethods", (paymentMethods) ->
    new class PaymentMethods
      paymentMethods: paymentMethods

      findByID: (id) ->
        for paymentMethod in @paymentMethods
          return paymentMethod if paymentMethod.id is id
