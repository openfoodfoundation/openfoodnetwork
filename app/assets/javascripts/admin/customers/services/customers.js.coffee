angular.module("admin.customers").factory "Customers", ($q, InfoDialog, RequestMonitor, CustomerResource, CurrentShop) ->
  new class Customers
    customers: []

    add: (email) ->
      params =
        enterprise_id: CurrentShop.shop.id
        email: email
      CustomerResource.create params, (customer) =>
        @customers.unshift customer if customer.id

    remove: (customer) ->
      params = id: customer.id
      CustomerResource.destroy params, =>
        i = @customers.indexOf customer
        @customers.splice i, 1 unless i < 0
      , (response) =>
        errors = response.data.errors
        if errors?
          InfoDialog.open 'error', errors[0]
        else
          InfoDialog.open 'error', "Could not delete customer: #{customer.email}"

    index: (params) ->
      request = CustomerResource.index(params, (data) => @customers = data)
      RequestMonitor.load(request.$promise)
      request.$promise

    update: (address, customer, addressType) ->
      params =
        id: customer.id
        customer:
          "#{addressType}_attributes": address
      CustomerResource.update params

