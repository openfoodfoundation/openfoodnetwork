Darkswarm.controller "ProductsCtrl", ($scope, $rootScope, Product, OrderCycle, FilterSelectorsService) ->
  $scope.Product = Product
  $scope.totalActive =  FilterSelectorsService.totalActive
  $scope.clearAll =  FilterSelectorsService.clearAll
  $scope.filterText =  FilterSelectorsService.filterText
  $scope.FilterSelectorsService =  FilterSelectorsService
  $scope.limit = 3
  $scope.ordering = {order: "name"}
  $scope.order_cycle = OrderCycle.order_cycle

  $scope.incrementLimit = ->
    if $scope.limit < $scope.Product.products.length
      $scope.limit = $scope.limit + 1 

  $scope.searchKeypress = (e)->
    code = e.keyCode || e.which
    if code == 13
      e.preventDefault()
