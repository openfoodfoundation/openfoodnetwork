Darkswarm.factory 'Product', ($resource) ->
  new class Product
    constructor: ->
      @update()
    
    # TODO: don't need to scope this into object
    # Already on object as far as controller scope is concerned
    data: 
      products: null
      loading: true

    update: =>
      @data.products = $resource("/shop/products").query =>
        @data.loading = false 
      @data
