angular.module("admin.customers").controller "customersCtrl", ($scope, $q, $filter, Customers, TagRuleResource, CurrentShop, RequestMonitor, Columns, pendingChanges, shops) ->
  $scope.shops = shops
  $scope.RequestMonitor = RequestMonitor
  $scope.submitAll = pendingChanges.submitAll
  $scope.add = Customers.add
  $scope.deleteCustomer = Customers.remove
  $scope.customerLimit = 20
  $scope.columns = Columns.columns

  $scope.confirmRefresh = (event) ->
    event.preventDefault() unless pendingChanges.unsavedCount() == 0 || confirm(t("unsaved_changes_warning"))

  $scope.$watch "shop_id", ->
    if $scope.shop_id?
      CurrentShop.shop = $filter('filter')($scope.shops, {id: $scope.shop_id})[0]
      Customers.index({enterprise_id: $scope.shop_id}).then (data) ->
        pendingChanges.removeAll()
        $scope.customers_form.$setPristine()
        $scope.customers = data

  $scope.findTags = (query) ->
    defer = $q.defer()
    params =
      enterprise_id: $scope.shop_id
    TagRuleResource.mapByTag params, (data) =>
      filtered = data.filter (tag) ->
        tag.text.toLowerCase().indexOf(query.toLowerCase()) != -1
      defer.resolve filtered
    defer.promise
