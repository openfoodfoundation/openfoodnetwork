angular.module("admin.enterprises").controller 'enterprisesCtrl', ($scope, Enterprises, Columns) ->
    Enterprises.loaded = false
    $scope.allEnterprises = Enterprises.index()

    $scope.loaded = ->
      Enterprises.loaded

    $scope.columns = Columns.setColumns
      name:     { name: "Name",     visible: true }
      type:     { name: "Type",     visible: true }
      status:   { name: "Status",   visible: true }
      manage:   { name: "Manage",   visible: true }
