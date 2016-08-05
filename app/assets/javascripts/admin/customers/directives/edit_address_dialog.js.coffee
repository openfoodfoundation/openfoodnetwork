angular.module("admin.customers").directive 'editAddressDialog', ($compile, $templateCache, DialogDefaults, CurrentShop, Customers) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    scope.$watch 'country', (newVal) ->
      if newVal
        scope.states = newVal.states

    template = $compile($templateCache.get('admin/edit_address_dialog.html'))(scope)
    template.dialog(DialogDefaults)

    element.bind 'click', (e) ->
      template.dialog('open')
