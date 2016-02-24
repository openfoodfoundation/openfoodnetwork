angular.module("admin.enterprises").controller 'indexPackagePanelCtrl', ($scope, $controller) ->
    angular.extend this, $controller('indexPanelCtrl', {$scope: $scope})
