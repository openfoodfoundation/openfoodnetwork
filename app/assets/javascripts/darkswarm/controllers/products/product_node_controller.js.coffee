Darkswarm.controller "ProductNodeCtrl", ($scope, $modal, FilterSelectorsService) ->
  $scope.enterprise = $scope.product.supplier # For the modal, so it's consistent

  $scope.triggerProductModal = ->
    $scope.productPropertySelectors = FilterSelectorsService.createSelectors()
    $modal.open(templateUrl: "product_modal.html", scope: $scope)

  $scope.hasVerticalScrollBar = (selector) ->
    elem = angular.element(document.querySelector(selector))
    return false unless elem[0]

    elem[0].scrollHeight > elem[0].clientHeight
