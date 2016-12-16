angular.module("admin.standingOrders").factory 'StandingOrderPrototype', ($http, $injector, InfoDialog, ConfirmDialog, StatusMessage) ->
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
    item._destroy = true

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
      orders_with_issues = @not_closed_proxy_orders.filter((po) -> po.update_issues.length > 0)
      if orders_with_issues.length > 0
        InfoDialog.open('error', null, 'admin/order_update_issues_dialog.html', { proxyOrders: orders_with_issues})
    , (response) =>
      StatusMessage.display 'failure', 'Oh no! I was unable to save your changes.'
      angular.extend(@errors, response.data.errors)

  cancel: ->
    ConfirmDialog.open('error', t('admin.standing_orders.confirm_cancel_msg'), {cancel: t('back'), confirm: t('yes_i_am_sure')})
    .then =>
      @$cancel().then angular.noop, ->
        InfoDialog.open 'error', t('admin.standing_orders.cancel_failure_msg')

  pause: ->
    ConfirmDialog.open('error', t('admin.standing_orders.confirm_pause_msg'), {confirm: t('yes_i_am_sure')})
    .then =>
      @$pause().then angular.noop, ->
        InfoDialog.open 'error', t('admin.standing_orders.pause_failure_msg')

  unpause: ->
    ConfirmDialog.open('error', t('admin.standing_orders.confirm_unpause_msg'), {confirm: t('yes_i_am_sure')})
    .then =>
      @$unpause().then angular.noop, ->
        InfoDialog.open 'error', t('admin.standing_orders.unpause_failure_msg')

  cancelOrder: (order) ->
    if order.id?
      $http.put("/admin/proxy_orders/#{order.id}/cancel").then (response) =>
        angular.extend(order,response.data)
      , (response) ->
        InfoDialog.open 'error', response.data.errors[0]

  resumeOrder: (order) ->
    if order.id?
      $http.put("/admin/proxy_orders/#{order.id}/resume").then (response) =>
        angular.extend(order,response.data)
      , (response) ->
        InfoDialog.open 'error', response.data.errors[0]
