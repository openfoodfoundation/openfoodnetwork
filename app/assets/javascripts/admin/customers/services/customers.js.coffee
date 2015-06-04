angular.module("admin.customers").factory 'Customers', (CustomerResource) ->
  new class Customers
    customers: []
    customers_by_id: {}
    loaded: false

    index: (params={}, callback=null) ->
    	CustomerResource.index params, (data) =>
        for customer in data
          @customers.push customer
          @customers_by_id[customer.id] = customer

        @loaded = true
        (callback || angular.noop)(@customers)

    	@customers
