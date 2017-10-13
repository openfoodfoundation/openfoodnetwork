Darkswarm.controller "ShopNodeCtrl", ($scope, HashNavigation, $anchorScroll) ->
  $scope.toggle = ->
    HashNavigation.toggle $scope.shop.hash

  $scope.open = ->
    HashNavigation.active($scope.shop.hash)

  if $scope.open()
    $anchorScroll()
