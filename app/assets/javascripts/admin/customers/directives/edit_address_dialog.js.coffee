angular.module("admin.customers").directive 'editAddressDialog', ($compile, $templateCache, $filter, DialogDefaults, Customers, StatusMessage) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    template = null
    scope.errors = []

    scope.$watch 'address.country_id', (newCountryID) ->
      if newCountryID
        scope.states = scope.filterStates(newCountryID)
        scope.clearState() unless scope.addressStateMatchesCountry()

    scope.updateAddress = ->
      scope.edit_address_form.$setPristine()
      if scope.edit_address_form.$valid
        Customers.update(scope.address, scope.customer, scope.addressType).$promise.then (data) ->
          scope.customer = data
          scope.errors = []
          template.dialog('close')
          StatusMessage.display('success', t('admin.customers.index.update_address_success'))
      else
        scope.errors.push(t('admin.customers.index.update_address_error'))

    element.bind 'click', (e) ->
      if e.target.id == 'bill-address-link'
        scope.addressType = 'bill_address'
      else
        scope.addressType = 'ship_address'
      scope.address = scope.customer[scope.addressType]
      scope.states = scope.filterStates(scope.address?.country_id)

      template = $compile($templateCache.get('admin/edit_address_dialog.html'))(scope)
      template.dialog(DialogDefaults)
      template.dialog('open')
      scope.$apply()

    scope.filterStates = (countryID) ->
      return [] unless countryID
      $filter('filter')(scope.availableCountries, {id: parseInt(countryID)}, true)[0].states

    scope.clearState = ->
      scope.address.state_id = ""

    scope.addressStateMatchesCountry = ->
      scope.states.some (state) -> state.id == scope.address.state_id