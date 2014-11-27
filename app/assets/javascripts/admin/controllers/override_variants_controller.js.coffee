angular.module("ofn.admin").controller "AdminOverrideVariantsCtrl", ($scope, Indexer, SpreeApiAuth, PagedFetcher, hubs, producers, hubPermissions, variantOverrides) ->
  $scope.hubs = hubs
  $scope.hub = null
  $scope.products = []
  $scope.producers = Indexer.index producers
  $scope.hubPermissions = hubPermissions
  $scope.variantOverrides = Indexer.index variantOverrides, 'variant_id'

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


  $scope.selectHub = ->
    $scope.hub = (hub for hub in hubs when hub.id == $scope.hub_id)[0]
