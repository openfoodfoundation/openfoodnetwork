angular.module("admin.resources").factory 'Products', ->
  new class Products
    byID: {}
    pristineByID: {}

    load: (products) ->
      for product in products
        @byID[product.id] = product
        @pristineByID[product.id] = angular.copy(product)
