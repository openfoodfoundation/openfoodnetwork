angular.module("ofn.admin").controller "AdminProductEditCtrl", ($scope, $timeout, $http, BulkProducts, DisplayProperties, dataFetcher, DirtyProducts, VariantUnitManager, StatusMessage, producers, Taxons, SpreeApiAuth, tax_categories) ->
    $scope.loading = true

    $scope.StatusMessage = StatusMessage

    $scope.columns =
      producer:             {name: "Producer",              visible: true}
      sku:                  {name: "SKU",                   visible: false}
      name:                 {name: "Name",                  visible: true}
      unit:                 {name: "Unit",                  visible: true}
      price:                {name: "Price",                 visible: true}
      on_hand:              {name: "On Hand",               visible: true}
      on_demand:            {name: "On Demand",             visible: false}
      category:             {name: "Category",              visible: false}
      tax_category:         {name: "Tax Category",          visible: false}
      inherits_properties:  {name: "Inherits Properties?",  visible: false}
      available_on:         {name: "Available On",          visible: false}

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
    $scope.tax_categories = tax_categories
    $scope.filterProducers = [{id: "0", name: ""}].concat $scope.producers
    $scope.filterTaxons = [{id: "0", name: ""}].concat $scope.taxons
    $scope.producerFilter = "0"
    $scope.categoryFilter = "0"
    $scope.products = BulkProducts.products
    $scope.filteredProducts = []
    $scope.currentFilters = []
    $scope.limit = 15
    $scope.productsWithUnsavedVariants = []
    $scope.query = ""
    $scope.DisplayProperties = DisplayProperties

    $scope.initialise = ->
      SpreeApiAuth.authorise()
      .then ->
        $scope.spree_api_key_ok = true
        $scope.fetchProducts()
      .catch (message) ->
        $scope.api_error_msg = message

    $scope.$watchCollection '[query, producerFilter, categoryFilter]', ->
      $scope.limit = 15 # Reset limit whenever searching

    $scope.fetchProducts = ->
      $scope.loading = true
      BulkProducts.fetch($scope.currentFilters).then ->
        $scope.resetProducts()
        $scope.loading = false


    $scope.resetProducts = ->
      DirtyProducts.clear()
      StatusMessage.clear()

    # $scope.matchProducer = (product) ->
    #   for producer in $scope.producers
    #     if angular.equals(producer.id, product.producer)
    #       product.producer = producer
    #       break


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
      DisplayProperties.setShowVariants product.id, true


    $scope.nextVariantId = ->
      $scope.variantIdCounter = 0 unless $scope.variantIdCounter?
      $scope.variantIdCounter -= 1
      $scope.variantIdCounter

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
      if product.variants.length > 1
        if !$scope.variantSaved(variant)
          $scope.removeVariant(product, variant)
        else
          if confirm("Are you sure?")
            $http(
              method: "DELETE"
              url: "/api/products/" + product.permalink_live + "/variants/" + variant.id + "/soft_delete"
            ).success (data) ->
              $scope.removeVariant(product, variant)
      else
        alert("The last variant cannot be deleted!")

    $scope.removeVariant = (product, variant) ->
      product.variants.splice product.variants.indexOf(variant), 1
      DirtyProducts.deleteVariant product.id, variant.id
      $scope.displayDirtyProducts()


    $scope.cloneProduct = (product) ->
      BulkProducts.cloneProduct product

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
        StatusMessage.display 'alert', 'No changes to save.'


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
        BulkProducts.updateVariantLists(data.products, $scope.productsWithUnsavedVariants)
        $timeout -> $scope.displaySuccess()
      ).error (data, status) ->
        if status == 400 && data.errors? && data.errors.length > 0
          errors = error + "\n" for error in data.errors
          alert "Saving failed with the following error(s):\n" + errors
          $scope.displayFailure "Save failed due to invalid data"
        else
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
          product = BulkProducts.find product.id
          variant.unit_value  = parseFloat(match[1])
          variant.unit_value  = null if isNaN(variant.unit_value)
          variant.unit_value *= product.variant_unit_scale if variant.unit_value && product.variant_unit_scale
          variant.unit_description = match[3]

    $scope.incrementLimit = ->
      if $scope.limit < $scope.products.length
        $scope.limit = $scope.limit + 5


    $scope.displayUpdating = ->
      StatusMessage.display 'progress', 'Saving...'


    $scope.displaySuccess = ->
      StatusMessage.display 'success', 'Changes saved.'


    $scope.displayFailure = (failMessage) ->
      StatusMessage.display 'failure', "Saving failed. #{failMessage}"


    $scope.displayDirtyProducts = ->
      if DirtyProducts.count() > 0
        message = if DirtyProducts.count() == 1 then "one product" else DirtyProducts.count() + " products"
        StatusMessage.display 'notice', "Changes to #{message} remain unsaved."
      else
        StatusMessage.clear()


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

        if product.hasOwnProperty("sku")
          filteredProduct.sku = product.sku
          hasUpdatableProperty = true
        if product.hasOwnProperty("name")
          filteredProduct.name = product.name
          hasUpdatableProperty = true
        if product.hasOwnProperty("producer_id")
          filteredProduct.supplier_id = product.producer_id
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
        if product.hasOwnProperty("on_demand") and filteredVariants.length == 0 #only update if no variants present
          filteredProduct.on_demand = product.on_demand
          hasUpdatableProperty = true
        if product.hasOwnProperty("category_id")
          filteredProduct.primary_taxon_id = product.category_id
          hasUpdatableProperty = true
        if product.hasOwnProperty("tax_category_id")
          filteredProduct.tax_category_id = product.tax_category_id
          hasUpdatableProperty = true
        if product.hasOwnProperty("inherits_properties")
          filteredProduct.inherits_properties = product.inherits_properties
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
    if variant.hasOwnProperty("on_demand")
      filteredVariant.on_demand = variant.on_demand
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
