Darkswarm.factory 'Product', ($resource) ->
  new class Product
    constructor: ->
      @update()
    
    # TODO: don't need to scope this into object
    # Already on object as far as controller scope is concerned
    products: null
    loading: true

    update: =>
      @loading = true 
      @products = $resource("/shop/products").query =>
        @loading = false 
      @
