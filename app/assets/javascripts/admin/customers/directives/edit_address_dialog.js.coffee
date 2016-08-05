angular.module("admin.customers").directive 'editAddressDialog', ($compile, $templateCache, $filter, DialogDefaults, Customers) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    scope.$watch 'address.country_id', (newVal) ->
      if newVal
        scope.states = scope.filter_states(newVal)

    scope.updateAddress = ->
      console.log(scope.edit_address_form)

    template = $compile($templateCache.get('admin/edit_address_dialog.html'))(scope)
    template.dialog(DialogDefaults)

    element.bind 'click', (e) ->
      scope.address = scope.customer.bill_address
      template.dialog('open')
      scope.$apply()

    scope.filter_states = (countryID) ->
      $filter('filter')(scope.availableCountries, {id: countryID})[0].states
