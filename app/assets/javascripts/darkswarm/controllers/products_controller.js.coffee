angular.module('Darkswarm').controller "ProductsCtrl", ($scope, $sce, $filter, $rootScope, Products, OrderCycle, OrderCycleResource, FilterSelectorsService, Cart, Dereferencer, Taxons, Properties, currentHub, $timeout, productGridViewFeature) ->
  $scope.Products = Products
  $scope.Cart = Cart
  $scope.query = ""
  $scope.taxonSelectors = FilterSelectorsService.createSelectors()
  $scope.propertySelectors = FilterSelectorsService.createSelectors()
  $scope.producerPropertySelectors = FilterSelectorsService.createSelectors()
  $scope.filtersActive = true
  $scope.page = 1
  $scope.per_page = 10
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.supplied_taxons = null
  $scope.supplied_properties = null
  $scope.supplied_producer_properties = null
  $scope.showFilterSidebar = false
  $scope.activeTaxons = []
  $scope.activeProperties = []
  $scope.activeProducerProperties = []
  $scope.productGridViewFeature = productGridViewFeature.enabled

  # Update filters after initial load of shop tab
  $timeout =>
    $scope.update_filters()

  # Update filters when order cycle changed
  $rootScope.$on "orderCycleSelected", ->
    $scope.update_filters()
    $scope.clearAll()
    $scope.page = 1

  $scope.update_filters = ->
    order_cycle_id = OrderCycle.order_cycle.order_cycle_id
    return unless order_cycle_id

    params = {
      id: order_cycle_id,
      distributor: currentHub.id
    }

    OrderCycleResource.taxons params, (data)=>
      $scope.supplied_taxons = data.map( (taxon) ->
        Taxons.taxons_by_id[taxon.id]
      ).filter (t) -> t?

    OrderCycleResource.properties params, (data)=>
      $scope.supplied_properties = {}
      data.map( (property) ->
        $scope.supplied_properties[property.id] = Properties.properties_by_id[property.id]
      )

      # Fetch Producer Properties ONLY after Product Properties have loaded
      OrderCycleResource.producerProperties params, (producer_data)=>
        $scope.supplied_producer_properties = {}
        
        # Extract an array of all names currently in the product properties bucket
        existing_names = (p.name for k, p of $scope.supplied_properties)
        
        producer_data.map( (property) ->
          prop_obj = Properties.properties_by_id[property.id]
          
          # Only add to the UI if the name isn't already in existing_names
          if prop_obj.name not in existing_names
            $scope.supplied_producer_properties[property.id] = prop_obj
        )

  $scope.loadMore = ->
    if ($scope.page * $scope.per_page) <= Products.products.length
      $scope.loadMoreProducts()

  $scope.$watch 'query', (newValue, oldValue) -> $scope.loadProducts() if newValue != oldValue
  $scope.$watchCollection 'activeTaxons', (newValue, oldValue) -> $scope.loadProducts() if newValue != oldValue
  $scope.$watchCollection 'activeProperties', (newValue, oldValue) -> $scope.loadProducts() if newValue != oldValue
  $scope.$watchCollection 'activeProducerProperties', (newValue, oldValue) -> $scope.loadProducts() if newValue != oldValue

  $scope.loadProducts = ->
    $scope.page = 1
    if $scope.productGridViewFeature
      $scope.updateProductGrid()
    else
      Products.update($scope.queryParams())

  # Reload the product grid turbo frame with the current search and filters
  $scope.updateProductGrid = ->
    frame = document.getElementById("shop-products")
    url = $scope.productGridUrl()
    return unless frame? && url?

    # The order cycle selection already reloads the frame, avoid loading it twice
    frame.setAttribute("src", url) if frame.getAttribute("src") != url

  $scope.productGridUrl = ->
    order_cycle_id = $scope.order_cycle.order_cycle_id
    return unless order_cycle_id

    params = new URLSearchParams()
    params.append('q[name_or_meta_keywords_or_variants_display_as_or_variants_display_name_or_variants_enterprise_name_cont]', $scope.query) if $scope.query
    params.append('q[with_properties][]', id) for id in $scope.activeProperties
    params.append('q[with_variants_enterprise_properties][]', id) for id in $scope.activeProducerProperties
    params.append('q[variants_primary_taxon_id_in_any][]', id) for id in $scope.activeTaxons

    query_string = params.toString()
    url = "/order_cycles/#{order_cycle_id}/products"
    if query_string then "#{url}?#{query_string}" else url

  $scope.loadMoreProducts = ->
    Products.update($scope.queryParams($scope.page + 1), true)
    $scope.page += 1

  $scope.queryParams = (page = null) ->
    {
      id: $scope.order_cycle.order_cycle_id,
      page: page || $scope.page,
      per_page: $scope.per_page,
      'q[name_or_meta_keywords_or_variants_display_as_or_variants_display_name_or_variants_enterprise_name_cont]': $scope.query,
      'q[with_properties][]': $scope.activeProperties,
      'q[with_variants_enterprise_properties][]': $scope.activeProducerProperties,
      'q[variants_primary_taxon_id_in_any][]': $scope.activeTaxons
    }

  $scope.searchKeypress = (e)->
    code = e.keyCode || e.which
    if code == 13
      e.preventDefault()

  $scope.appliedTaxonsList = ->
    $scope.activeTaxons.map( (taxon_id) ->
      Taxons.taxons_by_id[taxon_id].name
    ).join($scope.filtersJoinWord()) if $scope.activeTaxons?

  $scope.appliedPropertiesList = ->
    $scope.activeProperties.map( (property_id) ->
      Properties.properties_by_id[property_id].name
    ).join($scope.filtersJoinWord()) if $scope.activeProperties?

  $scope.appliedProducerPropertiesList = ->
    $scope.activeProducerProperties.map( (property_id) ->
      Properties.properties_by_id[property_id].name
    ).join($scope.filtersJoinWord()) if $scope.activeProducerProperties?


  $scope.filtersJoinWord = ->
    $sce.trustAsHtml(" <span class='join-word'>#{t('products_or')}</span> ")

  $scope.clearAll = ->
    $scope.clearQuery()
    $scope.clearFilters()

  $scope.clearQuery = ->
    $scope.query = ""

  $scope.clearFilters = ->
    $scope.taxonSelectors.clearAll()
    $scope.propertySelectors.clearAll()
    $scope.producerPropertySelectors.clearAll()

  $scope.refreshStaleData = ->
    # If the products template has already been loaded but the controller is being initialized
    # again after the template has switched, refresh loaded data to avoid conflicts
    if $scope.Products.products.length > 0
      $scope.Products.products = []
      $scope.update_filters()
      $scope.loadProducts()

  $scope.filtersCount = () ->
    $scope.taxonSelectors.totalActive() + $scope.propertySelectors.totalActive() + $scope.producerPropertySelectors.totalActive()

  $scope.toggleFilterSidebar = ->
    $scope.showFilterSidebar = !$scope.showFilterSidebar
