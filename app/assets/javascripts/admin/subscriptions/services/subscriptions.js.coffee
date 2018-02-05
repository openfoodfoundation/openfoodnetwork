angular.module("admin.subscriptions").factory 'Subscriptions', ($q, SubscriptionResource, Subscription, RequestMonitor) ->
  new class Subscriptions
    byID: {}
    pristineByID: {}

    index: (params={}, callback=null) ->
      request = SubscriptionResource.index params, (data) => @load(data)
      RequestMonitor.load(request.$promise)
      request

    load: (subscriptions) ->
      for subscription in subscriptions
        @byID[subscription.id] = subscription
        @pristineByID[subscription.id] = angular.copy(subscription)

    afterCreate: (id) ->
      return unless @byID[id]?
      @pristineByID[id] = angular.copy(@byID[id])

    afterUpdate: (id) ->
      return unless @byID[id]?
      @pristineByID[id] = angular.copy(@byID[id])

    afterRemoveItem: (id, deletedItemID) ->
      return unless @pristineByID[id]?
      for item, i in @pristineByID[id].subscription_line_items when item.id == deletedItemID
        @pristineByID[id].subscription_line_items.splice(i, 1)
