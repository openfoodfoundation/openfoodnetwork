angular.module("admin.customers").directive 'newCustomerDialog', ($rootScope, $compile, $templateCache, DialogDefaults, CurrentShop, Customers) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    scope.CurrentShop = CurrentShop
    scope.submitted = false
    scope.email = ""
    scope.errors = []
    scope.notice = null

    scope.addCustomer = ->
      scope.new_customer_form.$setPristine()
      scope.submitted = true
      scope.errors = []
      scope.notice = null
      if scope.new_customer_form.$valid
        params =
          enterprise_id: CurrentShop.shop.id
          email: scope.email
        Customers.add(params).then (result) ->
          if result.customer.id
            scope.email = ""
            scope.submitted = false
            if result.existed
              # Keep the dialog open so that the admin sees what happened.
              scope.notice = t('js.admin.customers.index.customer_already_exists',
                email: result.customer.email, shop_name: CurrentShop.shop.name)
            else
              template.dialog('close')
            $rootScope.$evalAsync()
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
        $rootScope.$evalAsync()
      else
        alert(t('js.customers.select_shop'))
