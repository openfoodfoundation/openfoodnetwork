Darkswarm.controller "ProductsCtrl", ($scope, $filter, $rootScope, Products, OrderCycle, FilterSelectorsService, Cart, Taxons, Properties) ->
  $scope.Products = Products
  $scope.Cart = Cart
  $scope.query = ""
  $scope.taxonSelectors = FilterSelectorsService.createSelectors()
  $scope.propertySelectors = FilterSelectorsService.createSelectors()
  $scope.filtersActive = true
  $scope.limit = 10
  $scope.order_cycle = OrderCycle.order_cycle
  # $scope.infiniteDisabled = true

  # All of this logic basically just replicates the functionality filtering an ng-repeat
  # except that it allows us to filter a separate list before rendering, meaning that
  # we can get much better performance when applying filters by resetting the limit on the
  # number of products being rendered each time a filter is changed.

  $scope.$watch "Products.loading", (newValue, oldValue) ->
    $scope.updateFilteredProducts()
    $scope.$broadcast("loadFilterSelectors") if !newValue

  $scope.incrementLimit = ->
    if $scope.limit < Products.products.length
      $scope.limit += 10
      $scope.updateVisibleProducts()

  $scope.$watch 'query', -> $scope.updateFilteredProducts()
  $scope.$watchCollection 'activeTaxons', -> $scope.updateFilteredProducts()
  $scope.$watchCollection 'activeProperties', -> $scope.updateFilteredProducts()

  $scope.updateFilteredProducts = ->
    $scope.limit = 10
    f1 = $filter('products')(Products.products, $scope.query)
    f2 = $filter('taxons')(f1, $scope.activeTaxons)
    $scope.filteredProducts = $filter('properties')(f2, $scope.activeProperties)
    $scope.updateVisibleProducts()

  $scope.updateVisibleProducts = ->
    $scope.visibleProducts = $filter('limitTo')($scope.filteredProducts, $scope.limit)

  $scope.searchKeypress = (e)->
    code = e.keyCode || e.which
    if code == 13
      e.preventDefault()

  $scope.appliedTaxonsList = ->
    $scope.activeTaxons.map( (taxon_id) ->
      Taxons.taxons_by_id[taxon_id].name
    ).join(" & ") if $scope.activeTaxons?

  $scope.appliedPropertiesList = ->
    $scope.activeProperties.map( (property_id) ->
      Properties.properties_by_id[property_id].name
    ).join(" & ") if $scope.activeProperties?

  $scope.clearAll = ->
    $scope.query = ""
    $scope.taxonSelectors.clearAll()
    $scope.propertySelectors.clearAll()
