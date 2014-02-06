productEditModule = angular.module("ofn.bulk_product_edit", ["ofn.shared_services"])

productEditModule.config [
  "$httpProvider"
  (provider) ->
    provider.defaults.headers.common["X-CSRF-Token"] = $("meta[name=csrf-token]").attr("content")
]


productEditModule.directive "ofnDecimal", ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    numRegExp = /^\d+(\.\d+)?$/
    element.bind "blur", ->
      scope.$apply ngModel.$setViewValue(ngModel.$modelValue)
      ngModel.$render()

    ngModel.$parsers.push (viewValue) ->
      return viewValue + ".0"  if viewValue.indexOf(".") == -1  if angular.isString(viewValue) and numRegExp.test(viewValue)
      viewValue


productEditModule.directive "ofnTrackProduct", ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    property_name = attrs.ofnTrackProduct
    ngModel.$parsers.push (viewValue) ->
      if ngModel.$dirty
        addDirtyProperty scope.dirtyProducts, scope.product.id, property_name, viewValue
        scope.displayDirtyProducts()
      viewValue


productEditModule.directive "ofnTrackVariant", ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    property_name = attrs.ofnTrackVariant
    ngModel.$parsers.push (viewValue) ->
      dirtyVariants = {}
      dirtyVariants = scope.dirtyProducts[scope.product.id].variants  if scope.dirtyProducts.hasOwnProperty(scope.product.id) and scope.dirtyProducts[scope.product.id].hasOwnProperty("variants")
      if ngModel.$dirty
        addDirtyProperty dirtyVariants, scope.variant.id, property_name, viewValue
        addDirtyProperty scope.dirtyProducts, scope.product.id, "variants", dirtyVariants
        scope.displayDirtyProducts()
      viewValue


productEditModule.directive "ofnToggleVariants", ->
  link: (scope, element, attrs) ->
    if scope.displayProperties[scope.product.id].showVariants
      element.removeClass "icon-chevron-right"
      element.addClass "icon-chevron-down"
    else
      element.removeClass "icon-chevron-down"
      element.addClass "icon-chevron-right"
    element.on "click", ->
      scope.$apply ->
        if scope.displayProperties[scope.product.id].showVariants
          scope.displayProperties[scope.product.id].showVariants = false
          element.removeClass "icon-chevron-down"
          element.addClass "icon-chevron-right"
        else
          scope.displayProperties[scope.product.id].showVariants = true
          element.removeClass "icon-chevron-right"
          element.addClass "icon-chevron-down"



productEditModule.directive "ofnToggleColumn", ->
  link: (scope, element, attrs) ->
    element.addClass "unselected"  unless scope.column.visible
    element.click "click", ->
      scope.$apply ->
        if scope.column.visible
          scope.column.visible = false
          element.addClass "unselected"
        else
          scope.column.visible = true
          element.removeClass "unselected"

productEditModule.directive "datetimepicker", [
  "$parse"
  ($parse) ->
    return (
      require: "ngModel"
      link: (scope, element, attrs, ngModel) ->
        element.datetimepicker
          dateFormat: "yy-mm-dd"
          timeFormat: "HH:mm:ss"
          stepMinute: 15
          onSelect: (dateText, inst) ->
            scope.$apply (scope) ->
              # Fires ngModel.$parsers
              ngModel.$setViewValue dateText
    )
]


productEditModule.controller "AdminProductEditCtrl", [
  "$scope", "$timeout", "$http", "dataFetcher"
  ($scope, $timeout, $http, dataFetcher) ->
    $scope.updateStatusMessage =
      text: ""
      style: {}

    $scope.columns =
      supplier:     {name: "Supplier",     visible: true}
      name:         {name: "Name",         visible: true}
      unit:         {name: "Unit",         visible: true}
      price:        {name: "Price",        visible: true}
      on_hand:      {name: "On Hand",      visible: true}
      available_on: {name: "Available On", visible: false}

    $scope.variant_unit_options = [
      ["Weight (g)", "weight_1"],
      ["Weight (kg)", "weight_1000"],
      ["Weight (T)", "weight_1000000"],
      ["Volume (mL)", "volume_0.001"],
      ["Volume (L)", "volume_1"],
      ["Volume (ML)", "volume_1000000"],
      ["Items", "items"]
    ]

    $scope.filterableColumns = [
      { name: "Supplier",       db_column: "supplier_name" },
      { name: "Name",           db_column: "name" }
    ]

    $scope.filterTypes = [
      { name: "Equals",         predicate: "eq" },
      { name: "Contains",       predicate: "cont" }
    ]

    $scope.optionTabs =
      filters:        { title: "Filter Products",   visible: false }
      column_toggle:  { title: "Toggle Columns",    visible: false }

    $scope.perPage = 25
    $scope.currentPage = 1
    $scope.products = []
    $scope.filteredProducts = []
    $scope.currentFilters = []
    $scope.totalCount = -> $scope.filteredProducts.length
    $scope.totalPages = -> Math.ceil($scope.totalCount()/$scope.perPage)
    $scope.firstVisibleProduct = -> ($scope.currentPage-1)*$scope.perPage+1
    $scope.lastVisibleProduct = -> Math.min($scope.totalCount(),$scope.currentPage*$scope.perPage)
    $scope.setPage = (page) -> $scope.currentPage = page
    $scope.minPage = -> Math.max(1,Math.min($scope.totalPages()-4,$scope.currentPage-2))
    $scope.maxPage = -> Math.min($scope.totalPages(),Math.max(5,$scope.currentPage+2))

    $scope.$watch ->
      $scope.totalPages()
    , (newVal, oldVal) ->
      $scope.currentPage = Math.max $scope.totalPages(), 1  if newVal != oldVal && $scope.totalPages() < $scope.currentPage

    $scope.initialise = (spree_api_key) ->
      authorise_api_reponse = ""
      dataFetcher("/api/users/authorise_api?token=" + spree_api_key).then (data) ->
        authorise_api_reponse = data
        $scope.spree_api_key_ok = data.hasOwnProperty("success") and data["success"] == "Use of API Authorised"
        if $scope.spree_api_key_ok
          $http.defaults.headers.common["X-Spree-Token"] = spree_api_key
          dataFetcher("/api/enterprises/managed?template=bulk_index&q[is_primary_producer_eq]=true").then (data) ->
            $scope.suppliers = data
            # Need to have suppliers before we get products so we can match suppliers to product.supplier
            $scope.fetchProducts()
        else if authorise_api_reponse.hasOwnProperty("error")
          $scope.api_error_msg = authorise_api_reponse("error")
        else
          api_error_msg = "You don't have an API key yet. An attempt was made to generate one, but you are currently not authorised, please contact your site administrator for access."


    $scope.fetchProducts = -> # WARNING: returns a promise
      $scope.loading = true
      queryString = $scope.currentFilters.reduce (qs,f) ->
        return qs + "q[#{f.property.db_column}_#{f.predicate.predicate}]=#{f.value};"
      , ""
      return dataFetcher("/api/products/managed?template=bulk_index;page=1;per_page=500;#{queryString}").then (data) ->
        $scope.resetProducts data
        $scope.loading = false


    $scope.resetProducts = (data) ->
      $scope.products = data
      $scope.dirtyProducts = {}
      $scope.setMessage $scope.updateStatusMessage, "", {}, false
      $scope.displayProperties ||= {}
      angular.forEach $scope.products, (product) ->
        $scope.unpackProduct product


    $scope.unpackProduct = (product) ->
      $scope.displayProperties ||= {}
      $scope.displayProperties[product.id] ||= showVariants: false
      $scope.matchSupplier product
      $scope.loadVariantUnit product


    $scope.matchSupplier = (product) ->
      for i of $scope.suppliers
        supplier = $scope.suppliers[i]
        if angular.equals(supplier, product.supplier)
          product.supplier = supplier
          break


    $scope.loadVariantUnit = (product) ->
      product.variant_unit_with_scale =
        if product.variant_unit && product.variant_unit_scale && product.variant_unit != 'items'
          "#{product.variant_unit}_#{product.variant_unit_scale}"
        else if product.variant_unit
          product.variant_unit
        else
          null

      if product.variants
        for variant in product.variants
          unit_value = $scope.variantUnitValue product, variant
          variant.unit_value_with_description = "#{unit_value || ''} #{variant.unit_description || ''}".trim()


    $scope.variantUnitValue = (product, variant) ->
      if variant.unit_value
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

    $scope.addFilter = (filter) ->
      existingfilterIndex = $scope.indexOfFilter filter
      if $scope.filterableColumns.indexOf(filter.property) >= 0 && $scope.filterTypes.indexOf(filter.predicate) >= 0 && filter.value != "" && filter.value != undefined
        if ($scope.dirtyProductCount() > 0 and confirm("Unsaved changes will be lost. Continue anyway?")) or ($scope.dirtyProductCount() == 0)
          if existingfilterIndex == -1
            $scope.currentFilters.push filter
            $scope.fetchProducts()
          else if confirm("'#{filter.predicate.name}' filter already exists on column '#{filter.property.name}'. Replace it?")
            $scope.currentFilters[existingfilterIndex] = filter
            $scope.fetchProducts()

    $scope.removeFilter = (filter) ->
      index = $scope.currentFilters.indexOf(filter)
      if index != -1
        $scope.currentFilters.splice index, 1
        $scope.fetchProducts()

    $scope.indexOfFilter = (filter) ->
      for existingFilter, i in $scope.currentFilters
        return i if filter.property == existingFilter.property && filter.predicate == existingFilter.predicate
      return -1

    $scope.editWarn = (product, variant) ->
      if ($scope.dirtyProductCount() > 0 and confirm("Unsaved changes will be lost. Continue anyway?")) or ($scope.dirtyProductCount() == 0)
        window.location = "/admin/products/" + product.permalink_live + ((if variant then "/variants/" + variant.id else "")) + "/edit"


    $scope.deleteProduct = (product) ->
      if confirm("Are you sure?")
        $http(
          method: "DELETE"
          url: "/api/products/" + product.id
        ).success (data) ->
          $scope.products.splice $scope.products.indexOf(product), 1
          delete $scope.dirtyProducts[product.id]  if $scope.dirtyProducts.hasOwnProperty(product.id)
          $scope.displayDirtyProducts()


    $scope.deleteVariant = (product, variant) ->
      if confirm("Are you sure?")
        $http(
          method: "DELETE"
          url: "/api/products/" + product.id + "/variants/" + variant.id
        ).success (data) ->
          product.variants.splice product.variants.indexOf(variant), 1
          delete $scope.dirtyProducts[product.id].variants[variant.id]  if $scope.dirtyProducts.hasOwnProperty(product.id) and $scope.dirtyProducts[product.id].hasOwnProperty("variants") and $scope.dirtyProducts[product.id].variants.hasOwnProperty(variant.id)
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
      Object.keys(product.variants).length > 0


    $scope.hasOnDemandVariants = (product) ->
      (variant for id, variant of product.variants when variant.on_demand).length > 0


    $scope.updateProducts = (productsToSubmit) ->
      $scope.displayUpdating()
      $http(
        method: "POST"
        url: "/admin/products/bulk_update"
        data:
          products: productsToSubmit
          filters: $scope.currentFilters
      ).success((data) ->
        # TODO: remove this check altogether, need to write controller tests if we want to test this behaviour properly
        # Note: Rob implemented subset(), which is a simpler alternative to productsWithoutDerivedAttributes(). However, it
        #       conflicted with some changes I made before merging my work, so for now I've reverted to the old way of
        #       doing things. TODO: Review together and decide on strategy here. -- Rohan, 14-1-2014
        #if subset($scope.productsWithoutDerivedAttributes(), data)

        if angular.toJson($scope.productsWithoutDerivedAttributes($scope.products)) == angular.toJson($scope.productsWithoutDerivedAttributes(data))
          $scope.resetProducts data
          $timeout -> $scope.displaySuccess()
        else
          $scope.displayFailure "Product lists do not match."
      ).error (data, status) ->
        $scope.displayFailure "Server returned with error status: " + status


    $scope.submitProducts = ->
      # Pack pack $scope.products, so they will match the list returned from the server,
      # then pack $scope.dirtyProducts, ensuring that the correct product info is sent to the server.
      $scope.packProduct product for id, product of $scope.products
      $scope.packProduct product for id, product of $scope.dirtyProducts

      productsToSubmit = filterSubmitProducts($scope.dirtyProducts)
      if productsToSubmit.length > 0
        $scope.updateProducts productsToSubmit # Don't submit an empty list
      else
        $scope.setMessage $scope.updateStatusMessage, "No changes to update.", color: "grey", 3000

    $scope.packProduct = (product) ->
      if product.variant_unit_with_scale
        match = product.variant_unit_with_scale.match(/^([^_]+)_([\d\.]+)$/)
        if match
          product.variant_unit = match[1]
          product.variant_unit_scale = parseFloat(match[2])
        else
          product.variant_unit = product.variant_unit_with_scale
          product.variant_unit_scale = null
      if product.variants
        for id, variant of product.variants
          $scope.packVariant product, variant


    $scope.packVariant = (product, variant) ->
      if variant.hasOwnProperty("unit_value_with_description")
        match = variant.unit_value_with_description.match(/^([\d\.]+|)( |)(.*)$/)
        if match
          product = $scope.findProduct(product.id)
          variant.unit_value  = parseFloat(match[1]) || null
          variant.unit_value *= product.variant_unit_scale if variant.unit_value && product.variant_unit_scale
          variant.unit_description = match[3]


    $scope.productsWithoutDerivedAttributes = (products) ->
      products_filtered = []
      if products
        products_filtered = $scope.deepCopyProducts products
        for product in products_filtered
          delete product.variant_unit_with_scale
          if product.variants
            for variant in product.variants
              delete variant.unit_value_with_description
              # If we end up live-updating this field, we might want to reinstate its verification here
              delete variant.options_text
      products_filtered


    $scope.deepCopyProducts = (products) ->
      copied_products = (angular.extend {}, product for product in products)
      for product in copied_products
        if product.variants
          product.variants = (angular.extend {}, variant for variant in product.variants)
      copied_products


    $scope.findProduct = (id) ->
      products = (product for product in $scope.products when product.id == id)
      if products.length == 0 then null else products[0]


    $scope.setMessage = (model, text, style, timeout) ->
      model.text = text
      model.style = style
      $timeout.cancel model.timeout  if model.timeout
      if timeout
        model.timeout = $timeout(->
          $scope.setMessage model, "", {}, false
        , timeout, true)


    $scope.displayUpdating = ->
      $scope.setMessage $scope.updateStatusMessage, "Updating...",
        color: "orange"
      , false


    $scope.displaySuccess = ->
      $scope.setMessage $scope.updateStatusMessage, "Update complete",
        color: "green"
      , 3000


    $scope.displayFailure = (failMessage) ->
      $scope.setMessage $scope.updateStatusMessage, "Updating failed. " + failMessage,
        color: "red"
      , 10000


    $scope.displayDirtyProducts = ->
      if $scope.dirtyProductCount() > 0
        $scope.setMessage $scope.updateStatusMessage, "Changes to " + $scope.dirtyProductCount() + " products remain unsaved.",
          color: "gray"
        , false
      else
        $scope.setMessage $scope.updateStatusMessage, "", {}, false


    $scope.dirtyProductCount = ->
      Object.keys($scope.dirtyProducts).length
]

productEditModule.filter "rangeArray", ->
  return (input,start,end) ->
    input.push(i) for i in [start..end]
    input

filterSubmitProducts = (productsToFilter) ->
  filteredProducts = []
  if productsToFilter instanceof Object
    angular.forEach productsToFilter, (product) ->
      if product.hasOwnProperty("id")
        filteredProduct = {}
        filteredVariants = []
        if product.hasOwnProperty("variants")
          angular.forEach product.variants, (variant) ->
            if not variant.deleted_at? and variant.hasOwnProperty("id")
              hasUpdateableProperty = false
              filteredVariant = {}
              filteredVariant.id = variant.id
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
              filteredVariants.push filteredVariant  if hasUpdatableProperty

        hasUpdatableProperty = false
        filteredProduct.id = product.id
        if product.hasOwnProperty("name")
          filteredProduct.name = product.name
          hasUpdatableProperty = true
        if product.hasOwnProperty("supplier")
          filteredProduct.supplier_id = product.supplier.id
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
        if product.hasOwnProperty("available_on")
          filteredProduct.available_on = product.available_on
          hasUpdatableProperty = true
        if filteredVariants.length > 0 # Note that the name of the property changes to enable mass assignment of variants attributes with rails
          filteredProduct.variants_attributes = filteredVariants
          hasUpdatableProperty = true
        filteredProducts.push filteredProduct  if hasUpdatableProperty

  filteredProducts


addDirtyProperty = (dirtyObjects, objectID, propertyName, propertyValue) ->
  if dirtyObjects.hasOwnProperty(objectID)
    dirtyObjects[objectID][propertyName] = propertyValue
  else
    dirtyObjects[objectID] = {}
    dirtyObjects[objectID]["id"] = objectID
    dirtyObjects[objectID][propertyName] = propertyValue


removeCleanProperty = (dirtyObjects, objectID, propertyName) ->
  delete dirtyObjects[objectID][propertyName]  if dirtyObjects.hasOwnProperty(objectID) and dirtyObjects[objectID].hasOwnProperty(propertyName)
  delete dirtyObjects[objectID]  if dirtyObjects.hasOwnProperty(objectID) and Object.keys(dirtyObjects[objectID]).length <= 1


toObjectWithIDKeys = (array) ->
  object = {}
  
  for i of array
    if array[i] instanceof Object and array[i].hasOwnProperty("id")
      object[array[i].id] = angular.copy(array[i])
      object[array[i].id].variants = toObjectWithIDKeys(array[i].variants)  if array[i].hasOwnProperty("variants") and array[i].variants instanceof Array
  
  object

subset = (bigArray,smallArray) ->
  if smallArray instanceof Array && bigArray instanceof Array && smallArray.length > 0
    for item in smallArray
      return false if angular.toJson(bigArray).indexOf(angular.toJson(item)) == -1
    return true
  else
    return false
