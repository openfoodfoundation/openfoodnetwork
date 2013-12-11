Shop.factory 'Product', ($resource) ->
  new class Product
    @products: null
    update: ->
      @products = $resource("/shop/products").query()
      console.log @products
      @products
    all: ->
      @products || @update()
