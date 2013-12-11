angular.module("Shop").controller "ProductsCtrl", ($scope, $rootScope, Product) ->
  $scope.products = Product.all()


  #$scope.order_cycle = OrderCycle.order_cycle
  #$scope.updateProducts = ->
    #$scope.products = Product.all()
  #$scope.$watch "order_cycle.order_cycle_id", $scope.updateProducts
  #$scope.updateProducts()



