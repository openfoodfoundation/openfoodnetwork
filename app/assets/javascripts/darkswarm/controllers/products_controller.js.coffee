Darkswarm.controller "ProductsCtrl", ($scope, $rootScope, Products, OrderCycle, FilterSelectorsService, Cart) ->
  $scope.Products = Products
  $scope.Cart = Cart
  $scope.totalActive =  FilterSelectorsService.totalActive
  $scope.clearAll =  FilterSelectorsService.clearAll
  $scope.filterText =  FilterSelectorsService.filterText
  $scope.FilterSelectorsService =  FilterSelectorsService
  $scope.filtersActive = true
  $scope.limit = 3
  $scope.ordering = 
    order: "primary_taxon.name"
  $scope.order_cycle = OrderCycle.order_cycle

  $scope.incrementLimit = ->
    if $scope.limit < Products.products.length
      $scope.limit = $scope.limit + 1 

  $scope.searchKeypress = (e)->
    code = e.keyCode || e.which
    if code == 13
      e.preventDefault()
