Darkswarm.factory 'Product', ($resource) ->
  new class Product
    data: {
      products: null
    }
    update: ->
      @data.products = $resource("/shop/products").query =>
        #console.log @products
      @data
    all: ->
      @data.products || @update()
