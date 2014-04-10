Darkswarm.factory 'Product', ($resource) ->
  new class Product
    data: {
      products: null
      loading: true
    }
    update: ->
      @data.products = $resource("/shop/products").query =>
        @data.loading = false 
      @data
    all: ->
      @data.products || @update()
