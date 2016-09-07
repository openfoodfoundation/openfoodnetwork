angular.module("admin.standingOrders").factory "StandingOrder", ($injector, $http, StatusMessage, StandingOrderResource) ->
  new class StandingOrder
    standingOrder: new StandingOrderResource()
    errors: {}

    constructor: ->
      if $injector.has('standingOrder')
        angular.extend(@standingOrder, $injector.get('standingOrder'))

    buildItem: (item) ->
      return false unless item.variant_id > 0
      return false unless item.quantity > 0
      estimate_query = "/admin/variants/#{item.variant_id}/price_estimate?"
      estimate_query += "shop_id=#{@standingOrder.shop_id};schedule_id=#{@standingOrder.schedule_id}"
      $http.get(estimate_query).then (response) =>
        angular.extend(response.data, item) # Add variant_id and qty
        @standingOrder.standing_line_items.push response.data
      , (response) =>
        alert(response.data.errors)

    save: ->
      StatusMessage.display 'progress', 'Saving...'
      delete @errors[k] for k, v of @errors
      @standingOrder.$save().then (response) =>
        StatusMessage.display 'success', 'Saved'
      , (response) =>
        StatusMessage.display 'failure', 'Oh no! I was unable to save your changes.'
        angular.extend(@errors, response.data.errors)
