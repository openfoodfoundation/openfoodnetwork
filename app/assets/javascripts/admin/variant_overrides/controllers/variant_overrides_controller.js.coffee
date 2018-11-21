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
  $scope.onDemandOptions = [
    { description: t('js.yes'), value: true },
    { description: t('js.no'), value: false }
  ]

  $scope.views = Views.setViews
    inventory:    { name: t('js.variant_overrides.inventory_products'), visible: true }
    hidden:       { name: t('js.variant_overrides.hidden_products'),    visible: false }
    new:          { name: t('js.variant_overrides.new_products'),       visible: false }

  $scope.bulkActions = [ name: t('js.variant_overrides.reset_stock_levels'), callback: 'resetStock' ]

  $scope.columns = Columns.columns

  $scope.resetSelectFilters = ->
    $scope.producerFilter = 0
    $scope.importDateFilter = '0'
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
      num = if DirtyVariantOverrides.count() == 1 then t('js.variant_overrides.one_override')  else "#{DirtyVariantOverrides.count()} " + t('js.variant_overrides.overrides')
      StatusMessage.display 'notice', t('js.variant_overrides.changes_to') + ' ' + num + ' ' + t('js.variant_overrides.remain_unsaved')
    else
      StatusMessage.clear()

  $scope.update = ->
    if DirtyVariantOverrides.count() == 0
      StatusMessage.display 'alert', t('js.variant_overrides.no_changes_to_save')
    else
      StatusMessage.display 'progress', t('js.saving')
      DirtyVariantOverrides.save()
      .success (updatedVos) ->
        DirtyVariantOverrides.clear()
        VariantOverrides.updateIds updatedVos
        $scope.variant_overrides_form.$setPristine()
        StatusMessage.display 'success', t('js.changes_saved')
        VariantOverrides.updateData updatedVos # Refresh page data
      .error (data, status) ->
        StatusMessage.display 'failure', $scope.updateError(data, status)


  $scope.updateError = (data, status) ->
    if status == 401
      t('js.variant_overrides.no_authorisation')

    else if status == 400 && data.errors?
      errors = []
      for field, field_errors of data.errors
        errors = errors.concat field_errors
      errors = errors.join ', '
      t('js.variant_overrides.some_trouble', {errors: errors})
    else
      t('js.oh_no')

  $scope.resetStock = ->
    if DirtyVariantOverrides.count() > 0
      StatusMessage.display 'alert', t('js.save_changes_first')
      $timeout ->
        $scope.displayDirty()
      , 3000 # 3 second delay
    else
      return unless $scope.hub_id?
      StatusMessage.display 'progress', t('js.variant_overrides.changing_on_hand_stock')
      $http
        method: "POST"
        url: "/admin/variant_overrides/bulk_reset"
        data: { hub_id: $scope.hub_id }
      .success (updatedVos) ->
        VariantOverrides.updateData updatedVos
        StatusMessage.display 'success', t('js.variant_overrides.stock_reset')
      .error (data, status) ->
        $timeout -> StatusMessage.display 'failure', $scope.updateError(data, status)
