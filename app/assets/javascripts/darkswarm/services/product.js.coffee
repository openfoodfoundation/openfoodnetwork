Shop.factory 'Product', ($resource) ->
  class Product
    @all: ->
      response = $resource("/shop/products").query()

