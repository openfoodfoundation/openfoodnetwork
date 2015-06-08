angular.module("admin.enterprises").controller 'indexShopPanelCtrl', ($scope) ->
  $scope.enterprise = angular.copy($scope.object())
