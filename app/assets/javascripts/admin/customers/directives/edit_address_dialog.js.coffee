angular.module("admin.customers").directive 'editAddressDialog', ($compile, $templateCache, $filter, DialogDefaults, Customers, StatusMessage) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    scope.errors = []

    scope.$watch 'address.country_id', (newVal) ->
      if newVal
        scope.states = scope.filter_states(newVal)

    scope.updateAddress = ->
      scope.edit_address_form.$setPristine()
      if scope.edit_address_form.$valid
        Customers.update(scope.address, scope.customer, scope.current_address).$promise.then (data) ->
          scope.customer = data
          template.dialog('close')
          StatusMessage.display('success', "Address updated successfully.")
      else
        scope.errors.push("Sorry! Please input all of the required fields!")


    template = $compile($templateCache.get('admin/edit_address_dialog.html'))(scope)
    template.dialog(DialogDefaults)

    element.bind 'click', (e) ->
      if e.target.id == 'bill-address-link'
        scope.current_address = 'bill_address'
      else
        scope.current_address = 'ship_address'
      scope.address = scope.customer[scope.current_address]

      template.dialog('open')
      scope.$apply()

    scope.filter_states = (countryID) ->
      $filter('filter')(scope.availableCountries, {id: countryID})[0].states
