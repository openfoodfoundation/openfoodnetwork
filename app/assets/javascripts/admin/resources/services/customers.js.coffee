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
        if customer.id
          @all.unshift customer
          @byID[customer.id] = customer
          @pristineByID[customer.id] = angular.copy(customer)

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
