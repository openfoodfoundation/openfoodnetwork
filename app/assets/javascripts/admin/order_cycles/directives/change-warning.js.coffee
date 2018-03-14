angular.module("admin.orderCycles").directive "changeWarning", (ConfirmDialog) ->
  restrict: "A"
  scope:
    orderCycle: '=changeWarning'
  link: (scope, element, attrs) ->
    acknowledged = false
    count = scope.orderCycle.subscriptions_count
    cancel = 'admin.order_cycles.date_warning.cancel'
    proceed = 'admin.order_cycles.date_warning.proceed'
    msg = t('admin.order_cycles.date_warning.msg', n: count)
    options = { cancel: t(cancel), confirm: t(proceed) }

    element.focus ->
      return if acknowledged
      return if moment(scope.orderCycle.orders_close_at).isBefore()
      return if count < 1
      ConfirmDialog.open('info', msg, options).then ->
        acknowledged = true
        element.siblings('img').trigger('click')
