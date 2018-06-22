angular.module("admin.orderCycles").directive "changeWarning", (ConfirmDialog) ->
  restrict: "A"
  scope:
    orderCycle: '=changeWarning'
  link: (scope, element, attrs) ->
    acknowledged = false
    cancel = 'admin.order_cycles.date_warning.cancel'
    proceed = 'admin.order_cycles.date_warning.proceed'
    msg = 'admin.order_cycles.date_warning.msg'
    options = { cancel: t(cancel), confirm: t(proceed) }

    isOpen = (orderCycle) ->
      moment(orderCycle.orders_open_at, "YYYY-MM-DD HH:mm:SS Z").isBefore() &&
      moment(orderCycle.orders_close_at, "YYYY-MM-DD HH:mm:SS Z").isAfter()

    element.focus ->
      count = scope.orderCycle.subscriptions_count
      return if acknowledged
      return unless isOpen(scope.orderCycle)
      return if count < 1
      ConfirmDialog.open('info', t(msg, n: count), options).then ->
        acknowledged = true
        element.siblings('img').trigger('click')
