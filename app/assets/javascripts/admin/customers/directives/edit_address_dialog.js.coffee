angular.module("admin.customers").directive 'editAddressDialog', ($compile, $templateCache, DialogDefaults, CurrentShop, Customers) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    template = $compile($templateCache.get('admin/edit_address_dialog.html'))(scope)
    template.dialog(DialogDefaults)

    console.log('xie')

    element.bind 'click', (e) ->
      template.dialog('open')
