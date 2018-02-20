# Used to display a message before redirecting to a link
angular.module("admin.subscriptions").directive "confirmOrderEdit", (ConfirmDialog, $window) ->
  restrict: "A"
  link: (scope, element, attrs) ->
    element.bind "click", (event) ->
      unless scope.proxyOrder.order_id?
        event.preventDefault()
        ConfirmDialog.open('error', t('admin.subscriptions.orders.confirm_edit'), {confirm: t('admin.subscriptions.yes_i_am_sure')}).then ->
          $window.open(attrs.href)
