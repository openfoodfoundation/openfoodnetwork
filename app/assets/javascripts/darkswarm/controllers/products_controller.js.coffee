Darkswarm.controller "ProductsCtrl", ($scope, $filter, $rootScope, Products, OrderCycle, FilterSelectorsService, Cart, Taxons, Properties) ->
  $scope.Products = Products
  $scope.Cart = Cart
  $scope.query = ""
  $scope.taxonSelectors = FilterSelectorsService.createSelectors()
  $scope.propertySelectors = FilterSelectorsService.createSelectors()
  $scope.filtersActive = true
  $scope.limit = 10
  $scope.order_cycle = OrderCycle.order_cycle

  $scope.$watch "Products.loading", (newValue, oldValue) ->
    $scope.$broadcast("loadFilterSelectors") if !newValue

  $scope.incrementLimit = ->
    $scope.limit += 10 if $scope.limit < Products.products.length

  $scope.$watchGroup ['query','taxonSelectors','propertySelectors'], ->
    $scope.limit = 10

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
