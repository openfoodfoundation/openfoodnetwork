angular.module("admin.lineItems").factory 'LineItemResource', ($resource) ->
  $resource('/admin/:orders/:order_number/line_items/:id.json', {}, {
    'index':
      method: 'GET'
      isArray: true
    'update':
      method: 'PUT'
      transformRequest: (data, headersGetter) =>
        requestData = {}
        requestData[attr] = data[attr] for attr in ["price", "quantity", "final_weight_volume"]
        angular.toJson(requestData)
  })
