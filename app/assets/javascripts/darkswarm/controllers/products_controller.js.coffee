angular.module("Shop").controller "ProductsCtrl", ($scope, Product) ->
  $scope.products = Product.all()


