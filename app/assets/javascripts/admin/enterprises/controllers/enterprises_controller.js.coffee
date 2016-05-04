angular.module("admin.enterprises").controller 'enterprisesCtrl', ($scope, $q, Enterprises, Columns) ->
    requests = []
    requests.push ($scope.allEnterprises = Enterprises.index(ams_prefix: "index")).$promise

    $q.all(requests).then ->
      $scope.loaded = true

    $scope.columns = Columns.columns
