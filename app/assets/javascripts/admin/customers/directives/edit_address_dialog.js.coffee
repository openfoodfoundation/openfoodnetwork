angular.module("admin.customers").directive 'editAddressDialog', ($rootScope, $compile, $templateCache, DialogDefaults, Customers, StatusMessage, CountryStates) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    template = null
    scope.errors = []

    scope.$watch 'address.country_id', (newCountryID) ->
      return unless newCountryID
      scope.states = CountryStates.statesFor(scope.availableCountries, newCountryID)
      unless CountryStates.addressStateMatchesCountryStates(scope.states, scope.address.state_id)
        scope.address.state_id = ""

    scope.updateAddress = ->
      scope.edit_address_form.$setPristine()
      if scope.edit_address_form.$valid
        Customers.update(scope.address, scope.customer, scope.addressType).$promise.then (data) ->
          scope.customer = data
          scope.errors = []
          template.dialog('close')
          $rootScope.$evalAsync()
          StatusMessage.display('success', t('admin.customers.index.update_address_success'))
      else
        scope.errors.push(t('admin.customers.index.update_address_error'))

    element.bind 'click', (e) ->
      if e.target.id == 'bill-address-link'
        scope.addressType = 'bill_address'
      else
        scope.addressType = 'ship_address'
      scope.address = scope.customer[scope.addressType]
      scope.states = CountryStates.statesFor(scope.availableCountries, scope.address?.country_id)

      template = $compile($templateCache.get('admin/edit_address_dialog.html'))(scope)
      template.dialog(DialogDefaults)
      template.dialog('open')
      $rootScope.$evalAsync()
