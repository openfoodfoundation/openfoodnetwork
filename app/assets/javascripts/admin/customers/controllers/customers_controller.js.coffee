angular.module("admin.customers").controller "customersCtrl", ($scope, CustomerResource, TagsResource, $q, Columns, pendingChanges, shops) ->
  $scope.shop = {}
  $scope.shops = shops
  $scope.submitAll = pendingChanges.submitAll

  $scope.columns = Columns.setColumns
    email:     { name: "Email",    visible: true }
    code:      { name: "Code",     visible: true }
    tags:      { name: "Tags",     visible: true }

  $scope.$watch "shop.id", ->
    if $scope.shop.id?
      $scope.customers = index {enterprise_id: $scope.shop.id}

  $scope.findTags = (query) ->
    defer = $q.defer()
    params =
      enterprise_id: $scope.shop.id
    TagsResource.index params, (data) =>
      filtered = data.filter (tag) ->
        tag.text.toLowerCase().indexOf(query.toLowerCase()) != -1
      defer.resolve filtered
    defer.promise

  $scope.add = (email) ->
    params =
      enterprise_id: $scope.shop.id
      email: email
    CustomerResource.create params, (customer) =>
      if customer.id
        $scope.customers.push customer
        $scope.quickSearch = customer.email

  $scope.deleteCustomer = (customer) ->
    params = id: customer.id
    CustomerResource.destroy params, ->
      i = $scope.customers.indexOf customer
      $scope.customers.splice i, 1 unless i < 0

  index = (params) ->
    $scope.loaded = false
    CustomerResource.index params, =>
      $scope.loaded = true
