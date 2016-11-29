angular.module("admin.standingOrders").factory 'StandingOrderPrototype', ($http, $injector, InfoDialog, StatusMessage) ->
  errors: {}

  buildItem: (item) ->
    return false unless item.variant_id > 0
    return false unless item.quantity > 0
    data = angular.extend({}, item, { shop_id: @shop_id, schedule_id: @schedule_id })
    $http.post("/admin/standing_line_items/build", data).then (response) =>
      @standing_line_items.push response.data
    , (response) =>
      InfoDialog.open 'error', response.data.errors[0]

  removeItem: (item) ->
    index = @standing_line_items.indexOf(item)
    if item.id?
      $http.delete("/admin/standing_line_items/#{item.id}").then (response) =>
        $injector.get('StandingOrders').afterRemoveItem(@id, item.id) if $injector.has('StandingOrders')
        @standing_line_items.splice(index,1)
      , (response) ->
        InfoDialog.open 'error', response.data.errors[0]
    else
      @standing_line_items.splice(index,1)

  create: ->
    StatusMessage.display 'progress', 'Saving...'
    delete @errors[k] for k, v of @errors
    @$save().then (response) =>
      StatusMessage.display 'success', 'Saved'
      $injector.get('StandingOrders').afterCreate(@id) if $injector.has('StandingOrders')
    , (response) =>
      StatusMessage.display 'failure', 'Oh no! I was unable to save your changes.'
      angular.extend(@errors, response.data.errors)

  update: ->
    StatusMessage.display 'progress', 'Saving...'
    delete @errors[k] for k, v of @errors
    @$update().then (response) =>
      StatusMessage.display 'success', 'Saved'
      $injector.get('StandingOrders').afterUpdate(@id) if $injector.has('StandingOrders')
    , (response) =>
      StatusMessage.display 'failure', 'Oh no! I was unable to save your changes.'
      angular.extend(@errors, response.data.errors)
