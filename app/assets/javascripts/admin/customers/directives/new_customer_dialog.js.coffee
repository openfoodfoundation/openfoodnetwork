angular.module("admin.customers").directive 'newCustomerDialog', ($compile, $injector, $templateCache, $window, CurrentShop, Customers) ->
  restrict: 'A'
  scope: true
  link: (scope, element, attr) ->
    scope.CurrentShop = CurrentShop
    scope.submitted = null
    scope.email = ""
    scope.errors = []

    scope.addCustomer = (valid) ->
      scope.submitted = scope.email
      scope.errors = []
      if valid
        Customers.add(scope.email).$promise.then (data) ->
          if data.id
            scope.email = ""
            scope.submitted = null
            template.dialog('close')
        , (response) ->
          if response.data.errors
            scope.errors.push(error) for error in response.data.errors
          else
            scope.errors.push("Sorry! Could not create '#{scope.email}'")
      return

    # Compile modal template
    template = $compile($templateCache.get('admin/new_customer_dialog.html'))(scope)

    # Set Dialog options
    template.dialog
      show: { effect: "fade", duration: 400 }
      hide: { effect: "fade", duration: 300 }
      autoOpen: false
      resizable: false
      width: $window.innerWidth * 0.4;
      modal: true
      open: (event, ui) ->
        $('.ui-widget-overlay').bind 'click', ->
          $(this).siblings('.ui-dialog').find('.ui-dialog-content').dialog('close')

    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      if CurrentShop.shop.id
        template.dialog('open')
      else
        alert('Please select a shop first')
