angular.module("admin.indexUtils").factory "resources", ($resource) ->
  LineItem = $resource '/api/v0/orders/:order_number/line_items/:line_item_id.json',
    { order_number: '@order_number', line_item_id: '@line_item_id'},
    'update': { method: 'PUT' }
  Customer = $resource '/admin/customers/:customer_id.json',
    { customer_id: '@customer_id'},
    'update': { method: 'PUT' }

  return {
    update: (change) ->
      params = {}
      data = {}
      resource = null

      switch change.type
        when "line_item"
          resource = LineItem
          params.order_number = change.object.order.number
          params.line_item_id = change.object.id
          data.line_item = {}
          data.line_item[change.attr] = change.value
        when "customer"
          resource = Customer
          params.customer_id = change.object.id
          data.customer = {}
          data.customer[change.attr] = change.value
        else ""

      resource.update(params, data)
  }
