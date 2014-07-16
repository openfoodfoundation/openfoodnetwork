Darkswarm.factory 'Product', ($resource, Enterprises, Dereferencer, Taxons) ->
  new class Products
    constructor: ->
      @update()
    
    # TODO: don't need to scope this into object
    # Already on object as far as controller scope is concerned
    products: null
    loading: true

    update: =>
      @loading = true 
      @products = $resource("/shop/products").query (products)=>
        @extend()
        @dereference()
        @loading = false 
      @
    
    dereference: ->
      for product in @products
        product.supplier = Enterprises.enterprises_by_id[product.supplier.id]
        Dereferencer.dereference product.taxons, Taxons.taxons_by_id

    extend: ->
      for product in @products
        if product.variants?.length > 0
          prices = (v.price for v in product.variants)
          product.price = Math.min.apply(null, prices)

        product.hasVariants = product.variants?.length > 0
