angular.module("admin.subscriptions").factory 'SubscriptionForm', ($window, StatusMessage) ->
  class SubscriptionForm
    form: null
    subscription: null
    errors: {}

    constructor: (form, subscription) ->
      @form = form
      @subscription = subscription

    save: =>
      return @formInvalid() unless @form.$valid
      delete @errors[k] for k, v of @errors
      @form.$setPristine()
      StatusMessage.display 'progress', 'Saving...'
      if @subscription.id?
        @subscription.update().then @successCallback, @errorCallback
      else
        @subscription.create().then @successCallback, @errorCallback

    successCallback: (response) =>
      StatusMessage.display 'success', 'Saved. Redirecting...'
      $window.location.href = "/admin/subscriptions"

    errorCallback: (response) =>
      if response.data?.errors?
        angular.extend(@errors, response.data.errors)
        keys = Object.keys(response.data.errors)
        StatusMessage.display 'failure', response.data.errors[keys[0]][0]
      else
        # Happens when there are sync issues between SO and initialised orders
        # We save the SO, but open a dialog, so want to stay on the page
        StatusMessage.display 'success', 'Saved'

    formInvalid: -> StatusMessage.display 'failure', t('admin.subscriptions.details.invalid_error')
