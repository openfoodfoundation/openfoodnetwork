angular.module("admin.customers").directive 'newCustomerDialog', ($compile, $templateCache, DialogDefaults, CurrentShop, Customers) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    scope.CurrentShop = CurrentShop
    scope.submitted = false
    scope.email = ""
    scope.errors = []

    scope.addCustomer = ->
      scope.new_customer_form.$setPristine()
      scope.submitted = true
      scope.errors = []
      if scope.new_customer_form.$valid
        params =
          enterprise_id: CurrentShop.shop.id
          email: scope.email
        Customers.add(params).$promise.then (data) ->
          if data.id
            scope.email = ""
            scope.submitted = false
            template.dialog('close')
        , (response) ->
          if response.data.errors
            scope.errors.push(error) for error in response.data.errors
          else
            scope.errors.push(t('js.customers.could_not_create') + " '#{scope.email}'")
      return

    # Compile modal template
    template = $compile($templateCache.get('admin/new_customer_dialog.html'))(scope)

    # Set Dialog options
    template.dialog(DialogDefaults)

    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      if CurrentShop.shop.id
        template.dialog('open')
      else
        alert(t('js.customers.select_shop'))
