angular.module("admin.customers").factory "Customers", ($q, RequestMonitor, CustomerResource, CurrentShop) ->
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

    index: (params) ->
      request = CustomerResource.index(params, (data) => @customers = data)
      RequestMonitor.load(request.$promise)
      request.$promise
