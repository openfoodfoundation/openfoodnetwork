angular.module("ofn.admin").controller "AdminOverrideVariantsCtrl", ($scope, Indexer, SpreeApiAuth, PagedFetcher, StatusMessage, hubs, producers, hubPermissions, VariantOverrides, DirtyVariantOverrides) ->
  $scope.hubs = hubs
  $scope.hub = null
  $scope.products = []
  $scope.producers = Indexer.index producers
  $scope.hubPermissions = hubPermissions
  $scope.variantOverrides = VariantOverrides.variantOverrides
  $scope.StatusMessage = StatusMessage

  $scope.initialise = ->
    SpreeApiAuth.authorise()
    .then ->
      $scope.spree_api_key_ok = true
      $scope.fetchProducts()
    .catch (message) ->
      $scope.api_error_msg = message


  $scope.fetchProducts = ->
    url = "/api/products/distributable?page=::page::;per_page=100"
    PagedFetcher.fetch url, (data) => $scope.addProducts data.products


  $scope.addProducts = (products) ->
    $scope.products = $scope.products.concat products
    VariantOverrides.ensureDataFor hubs, products


  $scope.selectHub = ->
    $scope.hub = (hub for hub in hubs when hub.id == $scope.hub_id)[0]


  $scope.displayDirty = ->
    if DirtyVariantOverrides.count() > 0
      num = if DirtyVariantOverrides.count() == 1 then "one override" else "#{DirtyVariantOverrides.count()} overrides"
      StatusMessage.display 'notice', "Changes to #{num} remain unsaved."
    else
      StatusMessage.clear()


  $scope.update = ->
    StatusMessage.display 'success', 'Changes saved.'