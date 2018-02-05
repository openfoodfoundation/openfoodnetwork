angular.module("admin.standingOrders").factory 'StandingOrderForm', ($window, StatusMessage) ->
  class StandingOrderForm
    form: null
    standingOrder: null
    errors: {}

    constructor: (form, standingOrder) ->
      @form = form
      @standingOrder = standingOrder

    save: =>
      return @formInvalid() unless @form.$valid
      delete @errors[k] for k, v of @errors
      @form.$setPristine()
      StatusMessage.display 'progress', 'Saving...'
      if @standingOrder.id?
        @standingOrder.update().then @successCallback, @errorCallback
      else
        @standingOrder.create().then @successCallback, @errorCallback

    successCallback: (response) =>
      StatusMessage.display 'success', 'Saved. Redirecting...'
      $window.location.href = "/admin/standing_orders"

    errorCallback: (response) =>
      if response.data?.errors?
        angular.extend(@errors, response.data.errors)
        keys = Object.keys(response.data.errors)
        StatusMessage.display 'failure', response.data.errors[keys[0]][0]
      else
        # Happens when there are sync issues between SO and initialised orders
        # We save the SO, but open a dialog, so want to stay on the page
        StatusMessage.display 'success', 'Saved'

    formInvalid: -> StatusMessage.display 'failure', t('admin.standing_orders.details.invalid_error')
