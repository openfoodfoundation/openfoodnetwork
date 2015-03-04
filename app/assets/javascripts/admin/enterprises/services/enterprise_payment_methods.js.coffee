angular.module("admin.enterprises")
  .factory "EnterprisePaymentMethods", (Enterprise, PaymentMethods) ->
    new class EnterprisePaymentMethods
      paymentMethods: PaymentMethods.paymentMethods

      constructor: ->
        for payment_method in @paymentMethods
          payment_method.selected = payment_method.id in Enterprise.enterprise.payment_method_ids

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
