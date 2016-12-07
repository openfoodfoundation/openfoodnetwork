angular.module("admin.customers").controller "customersCtrl", ($scope, $q, $filter, Customers, TagRuleResource, CurrentShop, RequestMonitor, Columns, pendingChanges, shops, availableCountries) ->
  $scope.shops = shops
  $scope.availableCountries = availableCountries
  $scope.RequestMonitor = RequestMonitor
  $scope.submitAll = pendingChanges.submitAll
  $scope.customerLimit = 20
  $scope.customers = Customers.all
  $scope.columns = Columns.columns

  $scope.confirmRefresh = (event) ->
    event.preventDefault() unless pendingChanges.unsavedCount() == 0 || confirm(t("unsaved_changes_warning"))

  $scope.$watch "shop_id", ->
    if $scope.shop_id?
      CurrentShop.shop = $filter('filter')($scope.shops, {id: $scope.shop_id})[0]
      Customers.index({enterprise_id: $scope.shop_id}).then (data) ->
        pendingChanges.removeAll()
        $scope.customers_form.$setPristine()

  $scope.shop_id = shops[0].id if shops.length == 1

  $scope.deleteCustomer = (customer) ->
    if confirm(t('admin.customers.index.confirm_delete'))
      Customers.remove(customer)

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
      enterprise_id: $scope.shop_id
    TagRuleResource.mapByTag params, (data) =>
      filtered = data.filter (tag) ->
        tag.text.toLowerCase().indexOf(query.toLowerCase()) != -1
      defer.resolve filtered
    defer.promise
