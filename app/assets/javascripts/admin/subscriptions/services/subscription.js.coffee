angular.module("admin.subscriptions").factory "Subscription", ($injector, SubscriptionResource) ->
  class Subscription extends SubscriptionResource

    constructor: ->
      if $injector.has('subscription')
        angular.extend(@, $injector.get('subscription'))
