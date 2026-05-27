angular.module('Darkswarm').controller "ProductNodeCtrl", ($scope, $modal, FilterSelectorsService) ->
  $scope.enterprise = $scope.product.supplier # For the modal, so it's consistent
  $scope.productPropertySelectors = FilterSelectorsService.createSelectors()

  $scope.currentProductImageIndex = 0
  $scope._productCarouselImages = null

  normalizeCarouselImage = (image) ->
    return null unless image

    imageUrl = image.url || image.large_url || image.image_url || image.small_url || image.thumb_url
    return null unless imageUrl

    {
      url: imageUrl
      alt: image.alt || $scope.product.name
      caption: image.caption
      thumb_url: image.thumb_url || image.small_url || imageUrl
    }

  $scope.productCarouselImages = ->
    return $scope._productCarouselImages if $scope._productCarouselImages

    images = ($scope.product.carouselImages || []).map(normalizeCarouselImage).filter(Boolean)

    if images.length == 0 && $scope.product.largeImage
      fallbackImage = normalizeCarouselImage(
        url: $scope.product.largeImage
        alt: $scope.product.name
      )
      images = [fallbackImage] if fallbackImage

    $scope._productCarouselImages = images

  $scope.currentProductImage = ->
    images = $scope.productCarouselImages()
    return null unless images.length

    images[$scope.currentProductImageIndex]

  $scope.selectProductImage = (index) ->
    images = $scope.productCarouselImages()
    return unless images.length

    imageCount = images.length
    $scope.currentProductImageIndex = ((index % imageCount) + imageCount) % imageCount

  $scope.previousProductImage = ->
    $scope.selectProductImage($scope.currentProductImageIndex - 1)

  $scope.nextProductImage = ->
    $scope.selectProductImage($scope.currentProductImageIndex + 1)

  $scope.triggerProductModal = ->
    $scope._productCarouselImages = null
    $scope.currentProductImageIndex = 0
    $modal.open(templateUrl: "product_modal.html", scope: $scope)
