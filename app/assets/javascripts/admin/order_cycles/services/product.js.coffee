angular.module('admin.orderCycles').factory('Product', ($resource) ->
  Product = $resource('/api/exchanges/:exchange_id/products.json', {}, {
    'index':
      method: 'GET'
      isArray: true
  })
  {
    Product: Product
    products: {}
    loaded: false

    index: (params={}, callback=null) ->
      Product.index params, (data) =>
        @products[params.enterprise_id] = []
        for product in data
          @products[params.enterprise_id].push(product)

        @loaded = true
        (callback || angular.noop)(@products[params.enterprise_id])

      this.products
  })
