Shop.factory 'Product', ($resource) ->
  new class Product
    @products: null
    update: ->
      @products = $resource("/shop/products").query()
    all: ->
      @products || @update()
