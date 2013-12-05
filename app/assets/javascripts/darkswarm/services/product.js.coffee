Shop.factory 'Product', ($resource) ->
  #return $resource("/shop/products")
  class Product
    @all: ->
      $resource("/shop/products").query()

  #new Product

