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
          variant_unit_value = @divideAsInteger variant.unit_value, product.variant_unit_scale
          parseFloat(window.bigDecimal.round(variant_unit_value, 2))
        else
          variant.unit_value
      else
        null

    # forces integer division to avoid javascript floating point imprecision
    # using one billion as the multiplier so that it works for numbers with up to 9 decimal places
    divideAsInteger: (a, b) ->
      (a * 1000000000) / (b * 1000000000)
