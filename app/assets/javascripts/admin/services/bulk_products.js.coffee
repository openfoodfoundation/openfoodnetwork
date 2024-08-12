angular.module("ofn.admin").factory "BulkProducts", (ProductResource, dataFetcher, $http) ->
  new class BulkProducts
    products: []
    pagination: {}

    fetch: (params) ->
      ProductResource.index params, (data) =>
        @products.length = 0
        @addProducts data.products
        angular.extend(@pagination, data.pagination)

    cloneProduct: (product) ->
      $http.post("/api/v0/products/" + product.id + "/clone").then (response) =>
        dataFetcher("/api/v0/products/" + response.data.id + "?template=bulk_show").then (newProduct) =>
          @unpackProduct newProduct
          @insertProductAfter(product, newProduct)

    updateVariantLists: (serverProducts) ->
      for server_product in serverProducts
        product = @findProductInList(server_product.id, @products)
        product.variants = server_product.variants
        @loadVariantUnitValues product.variants

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
      @loadVariantUnit product

    loadVariantUnit: (product) ->
      @loadVariantUnitValues product.variants if product.variants

    loadVariantUnitValues: (variants) ->
      for variant in variants
        @loadVariantUnitValue variant

    loadVariantUnitValue: (variant) ->
      variant.variant_unit_with_scale =
        if variant.variant_unit && variant.variant_unit_scale && variant.variant_unit != 'items'
          "#{variant.variant_unit}_#{variant.variant_unit_scale}"
        else if variant.variant_unit
          variant.variant_unit
        else
          null

      unit_value = @variantUnitValue variant
      unit_value = if unit_value? then unit_value else ''
      variant.unit_value_with_description = "#{unit_value} #{variant.unit_description || ''}".trim()

    variantUnitValue: (variant) ->
      if variant.unit_value?
        if variant.variant_unit_scale
          variant_unit_value = @divideAsInteger variant.unit_value, variant.variant_unit_scale
          parseFloat(window.bigDecimal.round(variant_unit_value, 2))
        else
          variant.unit_value
      else
        null

    # forces integer division to avoid javascript floating point imprecision
    # using one billion as the multiplier so that it works for numbers with up to 9 decimal places
    divideAsInteger: (a, b) ->
      (a * 1000000000) / (b * 1000000000)
