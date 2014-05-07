Darkswarm.controller "ProducerNodeCtrl", ($scope, Navigation, $anchorScroll) ->
  $scope.toggle = ->
    Navigation.navigate $scope.producer.path

  $scope.open = ->
    Navigation.active($scope.producer.path)

  if $scope.open()
    $anchorScroll()
