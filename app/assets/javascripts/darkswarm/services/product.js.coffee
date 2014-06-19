Darkswarm.factory 'Product', ($resource, Enterprises) ->
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
        @dereference()
        @loading = false 
      @
    
    dereference: ->
      for product in @products
        product.supplier = Enterprises.enterprises_by_id[product.supplier.id]
