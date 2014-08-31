Darkswarm.controller "ProducerNodeCtrl", ($scope, HashNavigation, $anchorScroll) ->
  $scope.toggle = ->
    HashNavigation.toggle $scope.producer.hash

  $scope.open = ->
    HashNavigation.active($scope.producer.hash)

  if $scope.open()
    $anchorScroll()
