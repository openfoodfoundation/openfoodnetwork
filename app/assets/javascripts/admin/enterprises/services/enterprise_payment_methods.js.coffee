angular.module("admin.enterprises")
  .factory "EnterprisePaymentMethods", (enterprise, PaymentMethods) ->
    new class EnterprisePaymentMethods
      paymentMethods: PaymentMethods.all

      constructor: ->
        for payment_method in @paymentMethods
          payment_method.selected = payment_method.id in enterprise.payment_method_ids

      displayColor: ->
        if @paymentMethods.length > 0 && @selectedCount() > 0
          "blue"
        else
          "red"

      selectedCount: ->
        @paymentMethods.reduce (count, payment_method) ->
          count++ if payment_method.selected
          count
        , 0
