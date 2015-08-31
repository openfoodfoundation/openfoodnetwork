angular.module("admin.variantOverrides").controller "AdminVariantOverridesCtrl", ($scope, Indexer, Columns, SpreeApiAuth, PagedFetcher, StatusMessage, hubs, producers, hubPermissions, VariantOverrides, DirtyVariantOverrides) ->
  $scope.hubs = Indexer.index hubs
  $scope.hub = null
  $scope.products = []
  $scope.producers = producers
  $scope.producersByID = Indexer.index producers
  $scope.hubPermissions = hubPermissions
  $scope.variantOverrides = VariantOverrides.variantOverrides
  $scope.StatusMessage = StatusMessage

  $scope.columns = Columns.setColumns
    producer:   { name: "Producer",           visible: true }
    product:    { name: "Product",            visible: true }
    sku:        { name: "SKU",                visible: false }
    price:      { name: "Price",              visible: true }
    on_hand:    { name: "On Hand",            visible: true }
    on_demand:  { name: "On Demand",          visible: false }
    reset:      { name: "Reset Stock Level",  visible: false }

  $scope.resetSelectFilters = ->
    $scope.producerFilter = 0
    $scope.query = ''

  $scope.resetSelectFilters()

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


  $scope.selectHub = ->
    $scope.hub = $scope.hubs[$scope.hub_id]

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
      StatusMessage.display 'progress', 'Changing on hand stock levels...'
      VariantOverrides.resetStock()
      .success (updatedVos) ->
        VariantOverrides.updateData updatedVos
        $timeout -> StatusMessage.display 'success', 'Stocks reset to defaults.'
