angular.module("admin.indexUtils").factory "resources", ($resource) ->
  LineItem = $resource '/api/orders/:order_number/line_items/:line_item_id.json',
    { order_number: '@order_cycle_id', line_item_id: '@line_item_id'},
    'update': { method: 'PUT' }

  return {
    update: (change) ->
      params = {}
      data = {}
      resource = null

      switch change.type
        when "line_item"
          resource = LineItem;
          params.order_number = change.object.order.number
          params.line_item_id = change.object.id
          data.line_item = {}
          data.line_item[change.attr] = change.value
        else ""

      resource.update(params, data)
  }
