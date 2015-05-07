angular.module("admin.customers").factory 'Customers', (CustomerResource) ->
  new class Customers
    customers: {}
    loaded: false

    index: (params={}, callback=null) ->
    	CustomerResource.index params, (data) =>
        for customer in data
          @customers[customer.id] = customer

        @loaded = true
        (callback || angular.noop)(@customers)

    	@customers
