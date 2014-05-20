Darkswarm.controller "ProductsCtrl", ($scope, $rootScope, Product, OrderCycle) ->
  $scope.data = Product.data
  $scope.limit = 3
  $scope.ordering = {order: "name"}
  $scope.order_cycle = OrderCycle.order_cycle

  $scope.incrementLimit = ->
    if $scope.limit < $scope.data.products.length
      $scope.limit = $scope.limit + 1 

  $scope.searchKeypress = (e)->
    code = e.keyCode || e.which
    if code == 13
      e.preventDefault()

  $scope.productPrice = (product) ->
