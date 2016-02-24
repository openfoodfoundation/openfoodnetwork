angular.module("admin.enterprises").controller 'indexProducerPanelCtrl', ($scope, $controller) ->
  angular.extend this, $controller('indexPanelCtrl', {$scope: $scope})

  $scope.changeToProducer = ->
    $scope.resetAttribute('sells')
    $scope.resetAttribute('producer_profile_only')
    $scope.enterprise.is_primary_producer = true

  $scope.changeToNonProducer = ->
    if $scope.enterprise.sells == 'own'
      $scope.enterprise.sells = 'any'
    if $scope.enterprise.producer_profile_only = true
      $scope.enterprise.producer_profile_only = false
    $scope.enterprise.is_primary_producer = false
