angular.module("ofn.admin").controller "ProductImageCtrl", ($scope, ProductImageService) ->
  $scope.imageUploader = ProductImageService.imageUploader
  $scope.imagePreview = ProductImageService.imagePreview

  $scope.$watch 'product.image_url', (newValue) ->
    $scope.imagePreview = newValue if newValue
