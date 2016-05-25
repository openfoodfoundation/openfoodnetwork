angular.module("admin.variantOverrides").controller "AdminVariantOverridesCtrl", ($scope, $http, $timeout, Indexer, Columns, Views, SpreeApiAuth, PagedFetcher, StatusMessage, RequestMonitor, hubs, producers, hubPermissions, InventoryItems, VariantOverrides, DirtyVariantOverrides) ->
  $scope.hubs = Indexer.index hubs
  $scope.hub_id = if hubs.length == 1 then hubs[0].id else null
  $scope.products = []
  $scope.producers = producers
  $scope.producersByID = Indexer.index producers
  $scope.hubPermissions = hubPermissions
  $scope.productLimit = 10
  $scope.variantOverrides = VariantOverrides.variantOverrides
  $scope.inventoryItems = InventoryItems.inventoryItems
  $scope.setVisibility = InventoryItems.setVisibility
  $scope.StatusMessage = StatusMessage
  $scope.RequestMonitor = RequestMonitor
  $scope.selectView = Views.selectView
  $scope.currentView = -> Views.currentView

  $scope.views = Views.setViews
    inventory:    { name: "Inventory Products", visible: true }
    hidden:       { name: "Hidden Products",    visible: false }
    new:          { name: "New Products",       visible: false }

  $scope.bulkActions = [ name: "Reset Stock Levels To Defaults", callback: 'resetStock' ]

  $scope.columns = Columns.columns

  $scope.resetSelectFilters = ->
    $scope.producerFilter = 0
    $scope.query = ''

  $scope.resetSelectFilters()

  $scope.filtersApplied = ->
    $scope.producerFilter != 0 || $scope.query != ''

  $scope.initialise = ->
    SpreeApiAuth.authorise()
    .then ->
      $scope.spree_api_key_ok = true
      $scope.fetchProducts()
    .catch (message) ->
      $scope.api_error_msg = message


  $scope.fetchProducts = ->
    url = "/api/products/overridable?page=::page::;per_page=100"
    PagedFetcher.fetch url, (data) => $scope.addProducts data.products


  $scope.addProducts = (products) ->
    $scope.products = $scope.products.concat products
    VariantOverrides.ensureDataFor hubs, products

  $scope.displayDirty = ->
    if DirtyVariantOverrides.count() > 0
      num = if DirtyVariantOverrides.count() == 1 then "one override" else "#{DirtyVariantOverrides.count()} overrides"
      StatusMessage.display 'notice', "Changes to #{num} remain unsaved."
    else
      StatusMessage.clear()

  $scope.update = ->
    if DirtyVariantOverrides.count() == 0
      StatusMessage.display 'alert', 'No changes to save.'
    else
      StatusMessage.display 'progress', 'Saving...'
      DirtyVariantOverrides.save()
      .success (updatedVos) ->
        DirtyVariantOverrides.clear()
        VariantOverrides.updateIds updatedVos
        $scope.variant_overrides_form.$setPristine()
        StatusMessage.display 'success', 'Changes saved.'
        VariantOverrides.updateData updatedVos # Refresh page data
      .error (data, status) ->
        StatusMessage.display 'failure', $scope.updateError(data, status)


  $scope.updateError = (data, status) ->
    if status == 401
      "I couldn't get authorisation to save those changes, so they remain unsaved."

    else if status == 400 && data.errors?
      errors = []
      for field, field_errors of data.errors
        errors = errors.concat field_errors
      errors = errors.join ', '
      "I had some trouble saving: #{errors}"
    else
      "Oh no! I was unable to save your changes."

  $scope.resetStock = ->
    if DirtyVariantOverrides.count() > 0
      StatusMessage.display 'alert', 'Save changes first.'
      $timeout ->
        $scope.displayDirty()
      , 3000 # 3 second delay
    else
      return unless $scope.hub_id?
      StatusMessage.display 'progress', 'Changing on hand stock levels...'
      $http
        method: "POST"
        url: "/admin/variant_overrides/bulk_reset"
        data: { hub_id: $scope.hub_id }
      .success (updatedVos) ->
        VariantOverrides.updateData updatedVos
        StatusMessage.display 'success', 'Stocks reset to defaults.'
      .error (data, status) ->
        $timeout -> StatusMessage.display 'failure', $scope.updateError(data, status)
