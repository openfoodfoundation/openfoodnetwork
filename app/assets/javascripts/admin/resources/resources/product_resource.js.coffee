angular.module("admin.resources").factory 'ProductResource', ($resource) ->
  $resource('/admin/product/:id/:action.json', {}, {
    'index':
      url: '/api/v0/products/bulk_products.json'
      method: 'GET'
  })
