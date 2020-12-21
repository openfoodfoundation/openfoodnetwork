angular.module("Darkswarm").factory 'Customers', (Customer) ->
  new class Customers
    all: []
    byID: {}

    index: (params={}) ->
      return @all if @all.length
      Customer.index params, (data) => @load(data)
      @all

    load: (customers) ->
      for customer in customers
        @all.push customer
        @byID[customer.id] = customer

    clearAllAllowCharges: () ->
      for customer in @index()
        customer.allow_charges = false
