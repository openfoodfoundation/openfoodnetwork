angular.module("ofn.admin").factory "BulkProducts", (PagedFetcher, dataFetcher) ->
  new class BulkProducts
    products: []

    fetch: (filters, onComplete) ->
      queryString = filters.reduce (qs,f) ->
        return qs + "q[#{f.property.db_column}_#{f.predicate.predicate}]=#{f.value};"
      , ""

      url = "/api/products/bulk_products?page=::page::;per_page=20;#{queryString}"
      PagedFetcher.fetch url, (data) => @addProducts data.products

    cloneProduct: (product) ->
      dataFetcher("/admin/products/" + product.permalink_live + "/clone.json").then (data) =>
        # Ideally we would use Spree's built in respond_override helper here to redirect the
        # user after a successful clone with .json in the accept headers
        # However, at the time of writing there appears to be an issue which causes the
        # respond_with block in the destroy action of Spree::Admin::Product to break
        # when a respond_overrride for the clone action is used.
        id = data.product.id
        dataFetcher("/api/products/" + id + "?template=bulk_show").then (newProduct) =>
          @insertProductAfter(product, newProduct)

    updateVariantLists: (serverProducts, productsWithUnsavedVariants) ->
      for product in productsWithUnsavedVariants
        server_product = @findProductInList(product.id, serverProducts)
        product.variants = server_product.variants
        @loadVariantUnitValues product

    find: (id) ->
      @findProductInList id, @products

    findProductInList: (id, product_list) ->
      products = (product for product in product_list when product.id == id)
      if products.length == 0 then null else products[0]

    addProducts: (products) ->
      for product in products
        @unpackProduct product
        @products.push product

    insertProductAfter: (product, newProduct) ->
      index = @products.indexOf(product)
      @products.splice(index + 1, 0, newProduct)

    unpackProduct: (product) ->
      #$scope.matchProducer product
      @loadVariantUnit product

    loadVariantUnit: (product) ->
      product.variant_unit_with_scale =
        if product.variant_unit && product.variant_unit_scale && product.variant_unit != 'items'
          "#{product.variant_unit}_#{product.variant_unit_scale}"
        else if product.variant_unit
          product.variant_unit
        else
          null

      @loadVariantUnitValues product if product.variants
      @loadVariantUnitValue product, product.master if product.master

    loadVariantUnitValues: (product) ->
      for variant in product.variants
        @loadVariantUnitValue product, variant

    loadVariantUnitValue: (product, variant) ->
      unit_value = @variantUnitValue product, variant
      unit_value = if unit_value? then unit_value else ''
      variant.unit_value_with_description = "#{unit_value} #{variant.unit_description || ''}".trim()

    variantUnitValue: (product, variant) ->
      if variant.unit_value?
        if product.variant_unit_scale
          variant.unit_value / product.variant_unit_scale
        else
          variant.unit_value
      else
        null
