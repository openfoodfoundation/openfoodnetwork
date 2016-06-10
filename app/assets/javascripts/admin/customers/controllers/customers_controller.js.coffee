angular.module("admin.customers").controller "customersCtrl", ($scope, $q, Customers, TagRuleResource, CurrentShop, RequestMonitor, Columns, pendingChanges, shops) ->
  $scope.shops = shops
  $scope.CurrentShop = CurrentShop
  $scope.RequestMonitor = RequestMonitor
  $scope.submitAll = pendingChanges.submitAll
  $scope.add = Customers.add
  $scope.deleteCustomer = Customers.remove
  $scope.customerLimit = 20
  $scope.columns = Columns.columns

  $scope.$watch "CurrentShop.shop", ->
    if $scope.CurrentShop.shop.id?
      Customers.index({enterprise_id: $scope.CurrentShop.shop.id}).then (data) ->
        $scope.customers = data

  $scope.checkForDuplicateCodes = ->
    delete this.customer.code unless this.customer.code
    this.duplicate = $scope.isDuplicateCode(this.customer.code)

  $scope.isDuplicateCode = (code) ->
    return false unless code
    customers = $scope.findByCode(code)
    customers.length > 1

  $scope.findByCode = (code) ->
    if $scope.customers
      $scope.customers.filter (customer) ->
        customer.code == code

  $scope.findTags = (query) ->
    defer = $q.defer()
    params =
      enterprise_id: $scope.CurrentShop.shop.id
    TagRuleResource.mapByTag params, (data) =>
      filtered = data.filter (tag) ->
        tag.text.toLowerCase().indexOf(query.toLowerCase()) != -1
      defer.resolve filtered
    defer.promise
