angular.module("admin.enterprises").controller 'enterprisesCtrl', ($scope, $q, Enterprises, Columns) ->
    requests = []
    requests.push ($scope.allEnterprises = Enterprises.index(ams_suffix: "index")).$promise

    $q.all(requests).then ->
      $scope.loaded = true

    $scope.columns = Columns.setColumns
      name:     { name: "Name",     visible: true }
      producer: { name: "Producer", visible: true }
      package:  { name: "Package",  visible: true }
      status:   { name: "Status",   visible: true }
      manage:   { name: "Manage",   visible: true }
