angular.module("admin.customers").controller "customersCtrl", ($scope, Customers, Columns, pendingChanges, shops) ->
  $scope.shop = null
  $scope.shops = shops
  $scope.submitAll = pendingChanges.submitAll

  $scope.columns = Columns.setColumns
    email:     { name: "Email",    visible: true }
    code:      { name: "Code",     visible: true }
    tags:      { name: "Tags",     visible: true }

  $scope.initialise = ->
    $scope.customers = Customers.index(enterprise_id: $scope.shop.id)

  $scope.loaded = ->
    Customers.loaded
