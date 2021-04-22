angular.module("Darkswarm").factory 'Customer', ($resource, $injector, Messages) ->
  Customer = $resource('/api/v0/customers/:id/:action.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'update':
      method: 'PUT'
      params:
        id: '@id'
      transformRequest: (data, headersGetter) ->
        angular.toJson(customer: data)
  })

  Customer.prototype.update = ->
    if @allow_charges
      Messages.loading(t('js.authorising'))
    @$update().then (response) =>
      if response.gateway_recurring_payment_client_secret && $injector.has('stripePublishableKey')
        Messages.clear()
        stripe = Stripe($injector.get('stripePublishableKey'), { stripeAccount: response.gateway_shop_id })
        stripe.confirmCardSetup(response.gateway_recurring_payment_client_secret).then (result) =>
          if result.error
            @allow_charges = false
            @$update(allow_charges: false)
            Messages.error(result.error.message)
          else
            Messages.success(t('js.changes_saved'))
      else
        Messages.success(t('js.changes_saved'))
    , (response) =>
      Messages.error(response.data.error)

  Customer
