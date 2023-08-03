angular.module("ofn.admin").controller "AdminProductEditCtrl", ($scope, $timeout, $filter, $http, $window, $location, BulkProducts, DisplayProperties, DirtyProducts, VariantUnitManager, StatusMessage, producers, Taxons, Columns, tax_categories, RequestMonitor, SortOptions, ErrorsParser, ProductFiltersUrl) ->
  $scope.StatusMessage = StatusMessage

  $scope.columns = Columns.columns

  $scope.variant_unit_options = VariantUnitManager.variantUnitOptions()

  $scope.RequestMonitor = RequestMonitor
  $scope.pagination = BulkProducts.pagination
  $scope.per_page_options = [
    {id: 15, name: t('js.admin.orders.index.per_page', results: 15)},
    {id: 50, name: t('js.admin.orders.index.per_page', results: 50)},
    {id: 100, name: t('js.admin.orders.index.per_page', results: 100)}
  ]

  $scope.q = {
    producerFilter: ""
    categoryFilter: ""
    importDateFilter: ""
    query: ""
    sorting: ""
  }

  $scope.sorting = "name asc"
  $scope.producers = producers
  $scope.taxons = Taxons.all
  $scope.tax_categories = tax_categories
  $scope.page = 1
  $scope.per_page = 15
  $scope.products = BulkProducts.products
  $scope.DisplayProperties = DisplayProperties

  $scope.sortOptions = SortOptions

  $scope.initialise = ->
    $scope.q = ProductFiltersUrl.loadFromUrl($location.search())
    $scope.fetchProducts()

  $scope.$watchCollection '[q.query, q.producerFilter, q.categoryFilter, q.importDateFilter, per_page]', ->
    $scope.page = 1 # Reset page when changing filters for new search

  $scope.changePage = (newPage) ->
    $scope.page = newPage
    $scope.fetchProducts()

  $scope.fetchProducts = ->
    removeClearedValues()
    params = {
      'q[name_cont]': $scope.q.query,
      'q[supplier_id_eq]': $scope.q.producerFilter,
      'q[primary_taxon_id_eq]': $scope.q.categoryFilter,
      'q[s]': $scope.sorting,
      import_date: $scope.q.importDateFilter,
      page: $scope.page,
      per_page: $scope.per_page
    }
    RequestMonitor.load(BulkProducts.fetch(params).$promise).then ->
      # update url with the filters used
      $location.search(ProductFiltersUrl.generate($scope.q))
      $scope.resetProducts()

  removeClearedValues = ->
    delete $scope.q.producerFilter if $scope.q.producerFilter == "0"
    delete $scope.q.categoryFilter if $scope.q.categoryFilter == "0"
    delete $scope.q.importDateFilter if $scope.q.importDateFilter == "0"

  $timeout ->
    if $scope.showLatestImport
      $scope.q.importDateFilter = $scope.importDates[1].id

  $scope.resetProducts = ->
    DirtyProducts.clear()
    StatusMessage.clear()

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
    $scope.q.query = ""
    $scope.q.producerFilter = "0"
    $scope.q.categoryFilter = "0"
    $scope.q.importDateFilter = "0"
    $scope.fetchProducts()

  $scope.$watch 'sortOptions', (sort) ->
    return unless sort && sort.predicate != ""

    $scope.sorting = sort.getSortingExpr(defaultDirection: "asc")
    $scope.fetchProducts()
  , true

  confirm_unsaved_changes = () ->
    (DirtyProducts.count() > 0 and confirm(t("unsaved_changes_confirmation"))) or (DirtyProducts.count() == 0)

  editProductUrl = (product, variant) ->
    "/admin/products/" + product.id + ((if variant then "/variants/" + variant.id else "")) + "/edit"

  $scope.editWarn = (product, variant) ->
    if confirm_unsaved_changes()
      $window.location.href = ProductFiltersUrl.buildUrl(editProductUrl(product, variant), $scope.q)

  $scope.toggleShowAllVariants = ->
    showVariants = !DisplayProperties.showVariants 0
    $scope.products.forEach (product) ->
      DisplayProperties.setShowVariants product.id, showVariants
    DisplayProperties.setShowVariants 0, showVariants

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
      tax_category_id: null
    DisplayProperties.setShowVariants product.id, true


  $scope.nextVariantId = ->
    $scope.variantIdCounter = 0 unless $scope.variantIdCounter?
    $scope.variantIdCounter -= 1
    $scope.variantIdCounter

  $scope.deleteProduct = (product) ->
    if confirm(t('are_you_sure'))
      $http(
        method: "DELETE"
        url: "/api/v0/products/" + product.id
      ).then (response) ->
        $scope.products.splice $scope.products.indexOf(product), 1
        DirtyProducts.deleteProduct product.id
        $scope.displayDirtyProducts()


  $scope.deleteVariant = (product, variant) ->
    if product.variants.length > 1
      if !$scope.variantSaved(variant)
        $scope.removeVariant(product, variant)
      else
        if confirm(t("are_you_sure"))
          $http(
            method: "DELETE"
            url: "/api/v0/products/" + product.id + "/variants/" + variant.id
          ).then (response) ->
            $scope.removeVariant(product, variant)
    else
      alert(t("delete_product_variant"))

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
      StatusMessage.display 'alert', t("products_change")


  $scope.updateProducts = (productsToSubmit) ->
    $scope.displayUpdating()
    $http(
      method: "POST"
      url: "/admin/products/bulk_update"
      data:
        products: productsToSubmit
        filters:
          'q[name_cont]': $scope.q.query
          'q[supplier_id_eq]': $scope.q.producerFilter
          'q[primary_taxon_id_eq]': $scope.q.categoryFilter
          'q[s]': $scope.sorting
          import_date: $scope.q.importDateFilter
        page: $scope.page
        per_page: $scope.per_page
    ).then((response) ->
      DirtyProducts.clear()
      BulkProducts.updateVariantLists(response.data.products || [])
      $timeout -> $scope.displaySuccess()
    ).catch (response) ->
      if response.status == 400 && response.data.errors?
        errorsString = ErrorsParser.toString(response.data.errors, response.status)
        $scope.displayFailure t("products_update_error") + "\n" + errorsString
      else
        $scope.displayFailure t("products_update_error_data") + response.status

  $scope.cancel = (destination) ->
    $window.location = destination

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
      match = variant.unit_value_with_description.match(/^([\d\.\,]+(?= |$)|)( |)(.*)$/)
      if match
        product = BulkProducts.find product.id
        variant.unit_value  = parseFloat(match[1].replace(",", "."))
        variant.unit_value  = null if isNaN(variant.unit_value)
        if variant.unit_value && product.variant_unit_scale
          variant.unit_value = parseFloat(window.bigDecimal.multiply(variant.unit_value, product.variant_unit_scale, 2))
        variant.unit_description = match[3]

  $scope.incrementLimit = ->
    if $scope.limit < $scope.products.length
      $scope.limit = $scope.limit + 5


  $scope.displayUpdating = ->
    StatusMessage.display 'progress', t("saving")


  $scope.displaySuccess = ->
    StatusMessage.display 'success',t("products_changes_saved")
    $scope.bulk_product_form.$setPristine()


  $scope.displayFailure = (failMessage) ->
    StatusMessage.display  'failure', t("products_update_error_msg") + " #{failMessage}"


  $scope.displayDirtyProducts = ->
    count = DirtyProducts.count()
    switch count
      when 0 then StatusMessage.clear()
      when 1 then StatusMessage.display 'notice', t("one_product_unsaved")
      else StatusMessage.display 'notice', t("products_unsaved", n: count)


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
        if product.hasOwnProperty("inherits_properties")
          filteredProduct.inherits_properties = product.inherits_properties
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
    if variant.hasOwnProperty("sku")
      filteredVariant.sku = variant.sku
      hasUpdatableProperty = true
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
    if variant.hasOwnProperty("tax_category_id")
      filteredVariant.tax_category_id = variant.tax_category_id
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
