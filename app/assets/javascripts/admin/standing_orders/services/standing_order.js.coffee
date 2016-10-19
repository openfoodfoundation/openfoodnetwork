angular.module("admin.standingOrders").factory "StandingOrder", ($injector, $http, StatusMessage, InfoDialog, StandingOrderResource) ->
  new class StandingOrder
    standingOrder: new StandingOrderResource()
    errors: {}

    constructor: ->
      if $injector.has('standingOrder')
        angular.extend(@standingOrder, $injector.get('standingOrder'))

    buildItem: (item) ->
      return false unless item.variant_id > 0
      return false unless item.quantity > 0
      data = angular.extend({}, item, { shop_id: @standingOrder.shop_id, schedule_id: @standingOrder.schedule_id })
      $http.post("/admin/standing_line_items/build", data).then (response) =>
        @standingOrder.standing_line_items.push response.data
      , (response) =>
        InfoDialog.open 'error', response.data.errors[0]

    create: ->
      StatusMessage.display 'progress', 'Saving...'
      delete @errors[k] for k, v of @errors
      @standingOrder.$save().then (response) =>
        StatusMessage.display 'success', 'Saved'
      , (response) =>
        StatusMessage.display 'failure', 'Oh no! I was unable to save your changes.'
        angular.extend(@errors, response.data.errors)

    update: ->
      StatusMessage.display 'progress', 'Saving...'
      delete @errors[k] for k, v of @errors
      @standingOrder.$update().then (response) =>
        StatusMessage.display 'success', 'Saved'
      , (response) =>
        StatusMessage.display 'failure', 'Oh no! I was unable to save your changes.'
        angular.extend(@errors, response.data.errors)
