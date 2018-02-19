# Provides additional auxillary functions to instances of SubsciptionResource
# Used to extend the prototype of the subscription resource created by SubscriptionResource

angular.module("admin.subscriptions").factory 'SubscriptionFunctions', ->
  estimatedSubtotal: ->
    @subscription_line_items.reduce (subtotal, item) ->
      return subtotal if item._destroy
      subtotal += item.price_estimate * item.quantity
    , 0

  estimatedTotal: ->
    @estimatedSubtotal()
