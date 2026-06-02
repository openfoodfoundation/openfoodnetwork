angular.module('Darkswarm').factory 'Products', (OrderCycleResource, OrderCycle, Shopfront, currentHub, Dereferencer, Taxons, Properties, Cart, Variants) ->
  new class Products
    constructor: ->
      @update()

    products: []
    fetched_products: []
    loading: true

    update: (params = {}, load_more = false) =>
      @loading = true
      order_cycle_id = OrderCycle.order_cycle.order_cycle_id

      if order_cycle_id == undefined
        @loading = false
        return

      params['id'] = order_cycle_id
      params['distributor'] = currentHub.id

      OrderCycleResource.products params, (data)=>
        @products = [] unless load_more
        @fetched_products = data
        @extend()
        @dereference()
        @registerVariants()
        @products = @products.concat(@fetched_products)
        @loading = false

    extend: ->
      for product in @fetched_products
        if product.variants?.length > 0
          prices = (v.price for v in product.variants)
          product.price = Math.min.apply(null, prices)
        product.hasVariants = product.variants?.length > 0

        images = product.images || []
        images = [product.image] if images.length == 0 && product.image

        showCaption = images.length > 1
        product.carouselImages = images.map (image, index) ->
          return null unless image

          caption = if showCaption then "#{product.name} - #{index + 1}" else null
          {
            url: image.large_url || image.image_url || image.small_url || image.thumb_url
            thumb_url: image.thumb_url || image.small_url || image.large_url || image.image_url
            alt: image.alt || product.name
            caption: caption
          }

        product.carouselImages = product.carouselImages.filter(Boolean)
        product.primaryImage = product.image?.small_url if product.image
        product.primaryImageOrMissing = product.primaryImage || "/noimage/small.png"
        product.largeImage = product.image?.large_url if product.image

    dereference: ->
      for product in @fetched_products
        product.enterprise = Shopfront.producers_by_id[product.variants[0].enterprise.id]
        Dereferencer.dereference product.taxons, Taxons.taxons_by_id

        product.properties = angular.copy(product.properties_with_values)
        Dereferencer.dereference product.properties, Properties.properties_by_id

    # May return different objects! If the variant has already been registered
    # by another service, we fetch those
    registerVariants: ->
      for product in @fetched_products
        if product.variants
          product.variant_names = ""
          product.variants = for variant in product.variants
            variant = Variants.register variant
            if product.name != variant.name_to_display
              product.variant_names += variant.name_to_display + " "
            variant.product = product
            variant
