Darkswarm.controller "ProducerNodeCtrl", ($scope, Navigation, $location, $anchorScroll) ->
  $scope.toggle = ->
    Navigation.navigate $scope.producer.path

  $scope.open = ->
    $location.path() == $scope.producer.path

  if $scope.open()
    $anchorScroll()
