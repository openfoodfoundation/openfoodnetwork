angular.module("admin.resources").factory "Customers", ($q, $injector, InfoDialog, RequestMonitor, CustomerResource) ->
  new class Customers
    all: []
    byID: {}
    pristineByID: {}

    constructor: ->
      if $injector.has('customers')
        @load($injector.get('customers'))

    add: (params) ->
      CustomerResource.create params, (customer) =>
        @merge(customer) if customer.id

    # Add the customer to the collection, or refresh it if we know it already.
    #
    # The server may respond with a customer we listed already, for example
    # when the given email differs only in case. Listing it twice breaks the
    # index table, because its ng-repeat tracks customers by id.
    merge: (customer) ->
      known = @byID[customer.id]
      if known?
        angular.extend known, customer
      else
        @all.unshift customer
        @byID[customer.id] = customer
      @pristineByID[customer.id] = angular.copy(@byID[customer.id])

    remove: (customer) ->
      params = id: customer.id
      CustomerResource.destroy params, =>
        i = @all.indexOf customer
        @all.splice i, 1 unless i < 0
      , (response) =>
        errors = response.data.errors
        if errors?
          InfoDialog.open 'error', errors[0]
        else
          InfoDialog.open 'error', t('js.resources.could_not_delete_customer') + ": #{customer.email}"

    index: (params) ->
      @clear()
      request = CustomerResource.index(params, (data) => @load(data))
      RequestMonitor.load(request.$promise)
      request.$promise

    load: (customers) ->
      for customer in customers
        @all.push customer
        @byID[customer.id] = customer
        @pristineByID[customer.id] = angular.copy(customer)

    update: (address, customer, addressType) ->
      params =
        id: customer.id
        customer:
          "#{addressType}_attributes": address
      CustomerResource.update params

    clear: ->
      @all.length = 0
