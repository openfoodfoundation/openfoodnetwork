angular.module("admin.enterprises").controller 'indexProducerPanelCtrl', ($scope) ->
  $scope.enterprise = angular.copy($scope.object())
  $scope.persisted = angular.copy($scope.object())
  $scope.attributes = ['is_primary_producer']

  $scope.saved = ->
    for attribute in $scope.attributes
      return false if $scope.enterprise[attribute] != $scope.persisted[attribute]
    true
