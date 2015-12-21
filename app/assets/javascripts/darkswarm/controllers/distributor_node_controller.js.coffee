Darkswarm.controller "DistributorNodeCtrl", ($scope, HashNavigation, $anchorScroll) ->
  $scope.toggle = ->
    HashNavigation.toggle $scope.distributor_id
    
  $scope.open = ->
    HashNavigation.active($scope.distributor_id)

  if $scope.open()
    $anchorScroll()
