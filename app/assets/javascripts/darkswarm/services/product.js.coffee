Darkswarm.factory 'Product', ($resource) ->
  new class Product
    constructor: ->
      @update()
    data: 
      products: null
      loading: true

    update: ->
      @data.products = $resource("/shop/products").query =>
        @data.loading = false 
      @data
