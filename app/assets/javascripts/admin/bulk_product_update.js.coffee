angular.module("ofn.admin").controller "AdminProductEditCtrl", [
  "$scope", "$timeout", "$http", "dataFetcher", "DirtyProducts", "VariantUnitManager", "producers", "Taxons",
  ($scope, $timeout, $http, dataFetcher, DirtyProducts, VariantUnitManager, producers, Taxons) ->
    $scope.updateStatusMessage =
      text: ""
      style: {}

    $scope.columns =
      producer:     {name: "Producer",      visible: true}
      name:         {name: "Name",          visible: true}
      unit:         {name: "Unit",          visible: true}
      price:        {name: "Price",         visible: true}
      on_hand:      {name: "On Hand",       visible: true}
      category:     {name: "Category",      visible: false}
      available_on: {name: "Available On",  visible: false}

    $scope.variant_unit_options = VariantUnitManager.variantUnitOptions()

    $scope.filterableColumns = [
      { name: "Producer",       db_column: "producer_name" },
      { name: "Name",           db_column: "name" }
    ]

    $scope.filterTypes = [
      { name: "Equals",         predicate: "eq" },
      { name: "Contains",       predicate: "cont" }
    ]

    $scope.optionTabs =
      filters:        { title: "Filter Products",   visible: false }


    $scope.producers = producers
    $scope.taxons = Taxons.taxons
    $scope.filterProducers = [{id: "0", name: ""}].concat $scope.producers
    $scope.filterTaxons = [{id: "0", name: ""}].concat $scope.taxons
    $scope.producerFilter = "0"
    $scope.categoryFilter = "0"
    $scope.products = []
    $scope.filteredProducts = []
    $scope.currentFilters = []
    $scope.limit = 15
    $scope.productsWithUnsavedVariants = []


    $scope.initialise = (spree_api_key) ->
      authorise_api_reponse = ""
      dataFetcher("/api/users/authorise_api?token=" + spree_api_key).then (data) ->
        authorise_api_reponse = data
        $scope.spree_api_key_ok = data.hasOwnProperty("success") and data["success"] == "Use of API Authorised"
        if $scope.spree_api_key_ok
          $http.defaults.headers.common["X-Spree-Token"] = spree_api_key
          $scope.fetchProducts()
        else if authorise_api_reponse.hasOwnProperty("error")
          $scope.api_error_msg = authorise_api_reponse("error")
        else
          api_error_msg = "You don't have an API key yet. An attempt was made to generate one, but you are currently not authorised, please contact your site administrator for access."

    $scope.$watchCollection '[query, producerFilter, categoryFilter]', ->
      $scope.limit = 15 # Reset limit whenever searching

    $scope.fetchProducts = -> # WARNING: returns a promise
      $scope.loading = true
      queryString = $scope.currentFilters.reduce (qs,f) ->
        return qs + "q[#{f.property.db_column}_#{f.predicate.predicate}]=#{f.value};"
      , ""
      return dataFetcher("/api/products/bulk_products?page=1;per_page=20;#{queryString}").then (data) ->
        $scope.resetProducts data.products
        $scope.loading = false
        if data.pages > 1
          for page in [2..data.pages]
            dataFetcher("/api/products/bulk_products?page=#{page};per_page=20;#{queryString}").then (data) ->
              for product in data.products
                $scope.unpackProduct product
                $scope.products.push product


    $scope.resetProducts = (data) ->
      $scope.products = data
      DirtyProducts.clear()
      $scope.setMessage $scope.updateStatusMessage, "", {}, false
      $scope.displayProperties ||= {}
      angular.forEach $scope.products, (product) ->
        $scope.unpackProduct product


    $scope.unpackProduct = (product) ->
      $scope.displayProperties ||= {}
      $scope.displayProperties[product.id] ||= showVariants: false
      #$scope.matchProducer product
      $scope.loadVariantUnit product


    # $scope.matchProducer = (product) ->
    #   for producer in $scope.producers
    #     if angular.equals(producer.id, product.producer)
    #       product.producer = producer
    #       break

    $scope.loadVariantUnit = (product) ->
      product.variant_unit_with_scale =
        if product.variant_unit && product.variant_unit_scale && product.variant_unit != 'items'
          "#{product.variant_unit}_#{product.variant_unit_scale}"
        else if product.variant_unit
          product.variant_unit
        else
          null

      $scope.loadVariantUnitValues product if product.variants
      $scope.loadVariantUnitValue product, product.master if product.master

    $scope.loadVariantUnitValues = (product) ->
      for variant in product.variants
        $scope.loadVariantUnitValue product, variant

    $scope.loadVariantUnitValue = (product, variant) ->
      unit_value = $scope.variantUnitValue product, variant
      unit_value = if unit_value? then unit_value else ''
      variant.unit_value_with_description = "#{unit_value} #{variant.unit_description || ''}".trim()


    $scope.variantUnitValue = (product, variant) ->
      if variant.unit_value?
        if product.variant_unit_scale
          variant.unit_value / product.variant_unit_scale
        else
          variant.unit_value
      else
        null


    $scope.updateOnHand = (product) ->
      on_demand_variants = []
      if product.variants
        on_demand_variants = (variant for id, variant of product.variants when variant.on_demand)

      unless product.on_demand || on_demand_variants.length > 0
        product.on_hand = $scope.onHand(product)


    $scope.onHand = (product) ->
      onHand = 0
      if product.hasOwnProperty("variants") and product.variants instanceof Object
        for id, variant of product.variants
          onHand = onHand + parseInt(if variant.on_hand > 0 then variant.on_hand else 0)
      else
        onHand = "error"
      onHand

    $scope.shiftTab = (tab) ->
      $scope.visibleTab.visible = false unless $scope.visibleTab == tab || $scope.visibleTab == undefined
      tab.visible = !tab.visible
      $scope.visibleTab = tab

    $scope.resetSelectFilters = ->
      $scope.query = ""
      $scope.producerFilter = "0"
      $scope.categoryFilter = "0"

    $scope.editWarn = (product, variant) ->
      if (DirtyProducts.count() > 0 and confirm("Unsaved changes will be lost. Continue anyway?")) or (DirtyProducts.count() == 0)
        window.location = "/admin/products/" + product.permalink_live + ((if variant then "/variants/" + variant.id else "")) + "/edit"


    $scope.addVariant = (product) ->
      product.variants.push
        id: $scope.nextVariantId()
        unit_value: null
        unit_description: null
        on_demand: false
        display_as: null
        display_name: null
        on_hand: null
        price: null
      $scope.productsWithUnsavedVariants.push product
      $scope.displayProperties[product.id].showVariants = true


    $scope.nextVariantId = ->
      $scope.variantIdCounter = 0 unless $scope.variantIdCounter?
      $scope.variantIdCounter -= 1
      $scope.variantIdCounter

    $scope.updateVariantLists = (server_products) ->
      for product in $scope.productsWithUnsavedVariants
        server_product = $scope.findProduct(product.id, server_products)
        product.variants = server_product.variants
        $scope.loadVariantUnitValues product

    $scope.deleteProduct = (product) ->
      if confirm("Are you sure?")
        $http(
          method: "DELETE"
          url: "/api/products/" + product.id + "/soft_delete"
        ).success (data) ->
          $scope.products.splice $scope.products.indexOf(product), 1
          DirtyProducts.deleteProduct product.id
          $scope.displayDirtyProducts()


    $scope.deleteVariant = (product, variant) ->
      if !$scope.variantSaved(variant)
        $scope.removeVariant(product, variant)
      else
        if confirm("Are you sure?")
          $http(
            method: "DELETE"
            url: "/api/products/" + product.permalink_live + "/variants/" + variant.id + "/soft_delete"
          ).success (data) ->
            $scope.removeVariant(product, variant)

    $scope.removeVariant = (product, variant) ->
      product.variants.splice product.variants.indexOf(variant), 1
      DirtyProducts.deleteVariant product.id, variant.id
      $scope.displayDirtyProducts()


    $scope.cloneProduct = (product) ->
      dataFetcher("/admin/products/" + product.permalink_live + "/clone.json").then (data) ->
        # Ideally we would use Spree's built in respond_override helper here to redirect the
        # user after a successful clone with .json in the accept headers
        # However, at the time of writing there appears to be an issue which causes the
        # respond_with block in the destroy action of Spree::Admin::Product to break
        # when a respond_overrride for the clone action is used.
        id = data.product.id
        dataFetcher("/api/products/" + id + "?template=bulk_show").then (data) ->
          newProduct = data
          $scope.unpackProduct newProduct
          $scope.products.push newProduct


    $scope.hasVariants = (product) ->
      product.variants.length > 0


    $scope.hasUnit = (product) ->
      product.variant_unit_with_scale?


    $scope.variantSaved = (variant) ->
      variant.hasOwnProperty('id') && variant.id > 0


    $scope.hasOnDemandVariants = (product) ->
      (variant for id, variant of product.variants when variant.on_demand).length > 0


    $scope.submitProducts = ->
      # Pack pack $scope.products, so they will match the list returned from the server,
      # then pack $scope.dirtyProducts, ensuring that the correct product info is sent to the server.
      $scope.packProduct product for id, product of $scope.products
      $scope.packProduct product for id, product of DirtyProducts.all()

      productsToSubmit = filterSubmitProducts(DirtyProducts.all())
      if productsToSubmit.length > 0
        $scope.updateProducts productsToSubmit # Don't submit an empty list
      else
        $scope.setMessage $scope.updateStatusMessage, "No changes to save.", color: "grey", 3000


    $scope.updateProducts = (productsToSubmit) ->
      $scope.displayUpdating()
      $http(
        method: "POST"
        url: "/admin/products/bulk_update"
        data:
          products: productsToSubmit
          filters: $scope.currentFilters
      ).success((data) ->
        DirtyProducts.clear()
        $scope.updateVariantLists(data.products)
        $timeout -> $scope.displaySuccess()
      ).error (data, status) ->
        $scope.displayFailure "Server returned with error status: " + status


    $scope.packProduct = (product) ->
      if product.variant_unit_with_scale
        match = product.variant_unit_with_scale.match(/^([^_]+)_([\d\.]+)$/)
        if match
          product.variant_unit = match[1]
          product.variant_unit_scale = parseFloat(match[2])
        else
          product.variant_unit = product.variant_unit_with_scale
          product.variant_unit_scale = null
      else
        product.variant_unit = product.variant_unit_scale = null

      $scope.packVariant product, product.master if product.master

      if product.variants
        for id, variant of product.variants
          $scope.packVariant product, variant


    $scope.packVariant = (product, variant) ->
      if variant.hasOwnProperty("unit_value_with_description")
        match = variant.unit_value_with_description.match(/^([\d\.]+(?= |$)|)( |)(.*)$/)
        if match
          product = $scope.findProduct(product.id, $scope.products)
          variant.unit_value  = parseFloat(match[1])
          variant.unit_value  = null if isNaN(variant.unit_value)
          variant.unit_value *= product.variant_unit_scale if variant.unit_value && product.variant_unit_scale
          variant.unit_description = match[3]

    $scope.findProduct = (id, product_list) ->
      products = (product for product in product_list when product.id == id)
      if products.length == 0 then null else products[0]

    $scope.incrementLimit = ->
      if $scope.limit < $scope.products.length
        $scope.limit = $scope.limit + 5

    $scope.setMessage = (model, text, style, timeout) ->
      model.text = text
      model.style = style
      $timeout.cancel model.timeout  if model.timeout
      if timeout
        model.timeout = $timeout(->
          $scope.setMessage model, "", {}, false
        , timeout, true)


    $scope.displayUpdating = ->
      $scope.setMessage $scope.updateStatusMessage, "Saving...",
        color: "#FF9906"
      , false


    $scope.displaySuccess = ->
      $scope.setMessage $scope.updateStatusMessage, "Changes saved.",
        color: "#9fc820"
      , 3000


    $scope.displayFailure = (failMessage) ->
      $scope.setMessage $scope.updateStatusMessage, "Saving failed. " + failMessage,
        color: "#DA5354"
      , 10000


    $scope.displayDirtyProducts = ->
      if DirtyProducts.count() > 0
        message = if DirtyProducts.count() == 1 then "one product" else DirtyProducts.count() + " products"
        $scope.setMessage $scope.updateStatusMessage, "Changes to " + message + " remain unsaved.",
          color: "gray"
        , false
      else
        $scope.setMessage $scope.updateStatusMessage, "", {}, false
]

filterSubmitProducts = (productsToFilter) ->
  filteredProducts = []
  if productsToFilter instanceof Object
    angular.forEach productsToFilter, (product) ->
      if product.hasOwnProperty("id")
        filteredProduct = {id: product.id}
        filteredVariants = []
        filteredMaster = null
        hasUpdatableProperty = false

        if product.hasOwnProperty("variants")
          angular.forEach product.variants, (variant) ->
            result = filterSubmitVariant variant
            filteredVariant = result.filteredVariant
            variantHasUpdatableProperty = result.hasUpdatableProperty
            filteredVariants.push filteredVariant  if variantHasUpdatableProperty

        if product.master?.hasOwnProperty("unit_value")
          filteredMaster ?= { id: product.master.id }
          filteredMaster.unit_value = product.master.unit_value
        if product.master?.hasOwnProperty("unit_description")
          filteredMaster ?= { id: product.master.id }
          filteredMaster.unit_description = product.master.unit_description
        if product.master?.hasOwnProperty("display_as")
          filteredMaster ?= { id: product.master.id }
          filteredMaster.display_as = product.master.display_as

        if product.hasOwnProperty("name")
          filteredProduct.name = product.name
          hasUpdatableProperty = true
        if product.hasOwnProperty("producer")
          filteredProduct.supplier_id = product.producer
          hasUpdatableProperty = true
        if product.hasOwnProperty("price")
          filteredProduct.price = product.price
          hasUpdatableProperty = true
        if product.hasOwnProperty("variant_unit_with_scale")
          filteredProduct.variant_unit       = product.variant_unit
          filteredProduct.variant_unit_scale = product.variant_unit_scale
          hasUpdatableProperty = true
        if product.hasOwnProperty("variant_unit_name")
          filteredProduct.variant_unit_name = product.variant_unit_name
          hasUpdatableProperty = true
        if product.hasOwnProperty("on_hand") and filteredVariants.length == 0 #only update if no variants present
          filteredProduct.on_hand = product.on_hand
          hasUpdatableProperty = true
        if product.hasOwnProperty("category")
          filteredProduct.primary_taxon_id = product.category
          hasUpdatableProperty = true
        if product.hasOwnProperty("available_on")
          filteredProduct.available_on = product.available_on
          hasUpdatableProperty = true
        if filteredMaster?
          filteredProduct.master_attributes = filteredMaster
          hasUpdatableProperty = true
        if filteredVariants.length > 0 # Note that the name of the property changes to enable mass assignment of variants attributes with rails
          filteredProduct.variants_attributes = filteredVariants
          hasUpdatableProperty = true
        filteredProducts.push filteredProduct  if hasUpdatableProperty

  filteredProducts


filterSubmitVariant = (variant) ->
  hasUpdatableProperty = false
  filteredVariant = {}
  if not variant.deleted_at? and variant.hasOwnProperty("id")
    filteredVariant.id = variant.id unless variant.id <= 0
    if variant.hasOwnProperty("on_hand")
      filteredVariant.on_hand = variant.on_hand
      hasUpdatableProperty = true
    if variant.hasOwnProperty("price")
      filteredVariant.price = variant.price
      hasUpdatableProperty = true
    if variant.hasOwnProperty("unit_value")
      filteredVariant.unit_value = variant.unit_value
      hasUpdatableProperty = true
    if variant.hasOwnProperty("unit_description")
      filteredVariant.unit_description = variant.unit_description
      hasUpdatableProperty = true
    if variant.hasOwnProperty("display_name")
      filteredVariant.display_name = variant.display_name
      hasUpdatableProperty = true
    if variant.hasOwnProperty("display_as")
      filteredVariant.display_as = variant.display_as
      hasUpdatableProperty = true
  {filteredVariant: filteredVariant, hasUpdatableProperty: hasUpdatableProperty}


toObjectWithIDKeys = (array) ->
  object = {}

  for i of array
    if array[i] instanceof Object and array[i].hasOwnProperty("id")
      object[array[i].id] = angular.copy(array[i])
      object[array[i].id].variants = toObjectWithIDKeys(array[i].variants)  if array[i].hasOwnProperty("variants") and array[i].variants instanceof Array

  object
