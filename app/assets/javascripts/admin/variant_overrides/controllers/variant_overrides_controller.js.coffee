angular.module("admin.variantOverrides").controller "AdminVariantOverridesCtrl", ($scope, $http, $timeout, Indexer, Columns, Views, PagedFetcher, StatusMessage, RequestMonitor, hubs, producers, hubPermissions, InventoryItems, VariantOverrides, DirtyVariantOverrides) ->
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
    { description: t('js.variant_overrides.on_demand.use_producer_settings'), value: null },
    { description: t('js.variant_overrides.on_demand.yes'), value: true },
    { description: t('js.variant_overrides.on_demand.no'), value: false }
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
    $scope.fetchProducts()

  $scope.fetchProducts = ->
    url = "/api/v0/products/overridable?page=::page::;per_page=100"
    PagedFetcher.fetch url, $scope.addProducts

  $scope.addProducts = (data) ->
    $scope.products = $scope.products.concat data.products
    VariantOverrides.ensureDataFor hubs, data.products

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
      .then (updatedVos) ->
        DirtyVariantOverrides.clear()
        VariantOverrides.updateIds updatedVos.data
        $scope.variant_overrides_form.$setPristine()
        StatusMessage.display 'success', t('js.changes_saved')
        VariantOverrides.updateData updatedVos.data # Refresh page data
      .catch (response) ->
        StatusMessage.display 'failure', $scope.updateError(response.data, response.status)


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
      .then (updatedVos) ->
        VariantOverrides.updateData updatedVos.data
        StatusMessage.display 'success', t('js.variant_overrides.stock_reset')
      .catch (response) ->
        $timeout -> StatusMessage.display 'failure', $scope.updateError(response.data, response.status)

  # Variant override count_on_hand field placeholder logic:
  #     on_demand true  -- Show "On Demand"
  #     on_demand false -- Show empty value to be set by the user
  #     on_demand nil   -- Show producer on_hand value
  $scope.countOnHandPlaceholder = (variant, hubId) ->
    variantOverride = $scope.variantOverrides[hubId][variant.id]

    if variantOverride.on_demand
      t('js.variants.on_demand.yes')
    else if variantOverride.on_demand == false
      ''
    else
      variant.on_hand

  # This method should only be used when the variant override on_demand is changed.
  #
  # Change the count_on_hand value to a suggested value.
  $scope.updateCountOnHand = (variant, hubId) ->
    variantOverride = $scope.variantOverrides[hubId][variant.id]

    suggested = $scope.countOnHandSuggestion(variant, hubId)
    return if suggested == variantOverride.count_on_hand
    variantOverride.count_on_hand = suggested
    DirtyVariantOverrides.set hubId, variant.id, variantOverride.id, 'count_on_hand', suggested

  # Suggest producer count_on_hand if variant has limited stock and variant override forces limited
  # stock. Otherwise, clear whatever value is set.
  $scope.countOnHandSuggestion = (variant, hubId) ->
    variantOverride = $scope.variantOverrides[hubId][variant.id]
    return null unless !variant.on_demand && variantOverride.on_demand == false
    variant.on_hand
