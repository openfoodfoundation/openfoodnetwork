angular.module("admin.enterprises")
  .controller "enterpriseCtrl", ($scope, Enterprise) ->
    $scope.enterprise = Enterprise.enterprise
