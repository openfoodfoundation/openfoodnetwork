angular.module("admin.resources").factory 'ProductResource', ($resource) ->
  $resource('/admin/product/:id/:action.json', {}, {
    'index':
      url: '/api/products/bulk_products.json'
      method: 'GET'
  })
