angular.module('admin.orderCycles').factory('Product', ($resource) ->
  ProductResource = $resource('/api/exchanges/:exchange_id/products.json', {}, {
    'index':
      method: 'GET'
      isArray: true
  })
  {
    ProductResource: ProductResource
    loaded: false

    index: (params={}, callback=null) ->
      ProductResource.index params, (data) =>
        @loaded = true
        (callback || angular.noop)(data)
  })
