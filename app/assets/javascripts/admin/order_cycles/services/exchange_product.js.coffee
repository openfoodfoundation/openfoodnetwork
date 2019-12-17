angular.module('admin.orderCycles').factory('ExchangeProduct', ($resource) ->
  ExchangeProductResource = $resource('/api/exchanges/:exchange_id/products.json', {}, {
    'index':
      method: 'GET'
      isArray: true
  })
  {
    ExchangeProductResource: ExchangeProductResource
    loaded: false

    index: (params={}, callback=null) ->
      ExchangeProductResource.index params, (data) =>
        @loaded = true
        (callback || angular.noop)(data)
  })
