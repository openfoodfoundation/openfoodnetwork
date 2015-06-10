angular.module("admin.enterprises").controller 'indexShopPanelCtrl', ($scope, $controller) ->
    angular.extend this, $controller('indexPanelCtrl', {$scope: $scope})
