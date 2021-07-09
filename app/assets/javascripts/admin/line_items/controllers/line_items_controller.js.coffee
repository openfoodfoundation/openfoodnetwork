angular.module("admin.lineItems").controller 'LineItemsCtrl', ($scope, $timeout, $http, $q, StatusMessage, Columns, SortOptions, Dereferencer, Orders, LineItems, Enterprises, OrderCycles, VariantUnitManager, RequestMonitor) ->
  $scope.initialized = false
  $scope.RequestMonitor = RequestMonitor
  $scope.line_items = LineItems.all
  $scope.confirmDelete = true
  $scope.startDate = moment().startOf('day').subtract(7, 'days').format('YYYY-MM-DD')
  $scope.endDate = moment().startOf('day').format('YYYY-MM-DD')
  $scope.bulkActions = [ { name: t("admin.orders.bulk_management.actions_delete"), callback: 'deleteLineItems' } ]
  $scope.selectedUnitsProduct = {}
  $scope.selectedUnitsVariant = {}
  $scope.sharedResource = false
  $scope.columns = Columns.columns
  $scope.sorting = SortOptions

  $scope.confirmRefresh = ->
    LineItems.allSaved() || confirm(t("unsaved_changes_warning"))

  $scope.resetFilters = ->
    $scope.distributorFilter = ''
    $scope.supplierFilter = ''
    $scope.orderCycleFilter = ''
    $scope.quickSearch = ''

  $scope.resetSelectFilters = ->
    $scope.resetFilters()
    $scope.refreshData()

  $scope.refreshData = ->
    unless !$scope.orderCycleFilter? || $scope.orderCycleFilter == ''
      $scope.setOrderCycleDateRange()

    $scope.formattedStartDate = moment($scope.startDate).format()
    $scope.formattedEndDate = moment($scope.endDate).add(1,'day').format()

    return unless moment($scope.formattedStartDate).isValid() and moment($scope.formattedEndDate).isValid()

    $scope.loadOrders()
    $scope.loadLineItems()

    unless $scope.initialized
      $scope.loadAssociatedData()

    $scope.dereferenceLoadedData()

  $scope.setOrderCycleDateRange = ->
    start_date = OrderCycles.byID[$scope.orderCycleFilter].orders_open_at
    end_date = OrderCycles.byID[$scope.orderCycleFilter].orders_close_at
    format = "YYYY-MM-DD HH:mm:ss Z"
    $scope.startDate = moment(start_date, format).format('YYYY-MM-DD')
    $scope.endDate = moment(end_date, format).startOf('day').format('YYYY-MM-DD')

  $scope.loadOrders = ->
    RequestMonitor.load $scope.orders = Orders.index(
      "q[state_not_eq]": "canceled",
      "q[shipment_state_not_eq]": "shipped",
      "q[completed_at_not_null]": "true",
      "q[distributor_id_eq]": $scope.distributorFilter,
      "q[order_cycle_id_eq]": $scope.orderCycleFilter,
      "q[completed_at_gteq]": $scope.formattedStartDate,
      "q[completed_at_lt]": $scope.formattedEndDate
    )

  $scope.loadLineItems = ->
    RequestMonitor.load LineItems.index(
      "q[order_state_not_eq]": "canceled",
      "q[order_shipment_state_not_eq]": "shipped",
      "q[order_completed_at_not_null]": "true",
      "q[order_distributor_id_eq]": $scope.distributorFilter,
      "q[variant_product_supplier_id_eq]": $scope.supplierFilter,
      "q[order_order_cycle_id_eq]": $scope.orderCycleFilter,
      "q[order_completed_at_gteq]": $scope.formattedStartDate,
      "q[order_completed_at_lt]": $scope.formattedEndDate
    )

  $scope.loadAssociatedData = ->
    RequestMonitor.load $scope.distributors = Enterprises.index(action: "visible", ams_prefix: "basic", "q[sells_in][]": ["own", "any"])
    RequestMonitor.load $scope.orderCycles = OrderCycles.index(ams_prefix: "basic", as: "distributor", "q[orders_close_at_gt]": "#{moment().subtract(90,'days').format()}")
    RequestMonitor.load $scope.suppliers = Enterprises.index(action: "visible", ams_prefix: "basic", "q[is_primary_producer_eq]": "true")

  $scope.dereferenceLoadedData = ->
    RequestMonitor.load $q.all([$scope.orders.$promise, $scope.distributors.$promise, $scope.orderCycles.$promise, $scope.suppliers.$promise, $scope.line_items.$promise]).then ->
      Dereferencer.dereferenceAttr $scope.orders, "distributor", Enterprises.byID
      Dereferencer.dereferenceAttr $scope.orders, "order_cycle", OrderCycles.byID
      Dereferencer.dereferenceAttr $scope.line_items, "supplier", Enterprises.byID
      Dereferencer.dereferenceAttr $scope.line_items, "order", Orders.byID
      $scope.bulk_order_form.$setPristine()
      StatusMessage.clear()

      unless $scope.initialized
        $scope.initialized = true

  $scope.$watch 'bulk_order_form.$dirty', (newVal, oldVal) ->
    if newVal == true
      StatusMessage.display 'notice', t('js.unsaved_changes')

  $scope.submit = ->
    if $scope.bulk_order_form.$valid
      StatusMessage.display 'progress', t('js.saving')
      $q.all(LineItems.saveAll()).then(->
        StatusMessage.display 'success', t('js.all_changes_saved')
        $scope.bulk_order_form.$setPristine()
      ).catch ->
        StatusMessage.display 'failure', t "unsaved_changes_error"
    else
      StatusMessage.display 'failure', t "unsaved_changes_error"

  $scope.deleteLineItem = (lineItem) ->
    if ($scope.confirmDelete && confirm(t "are_you_sure")) || !$scope.confirmDelete
      LineItems.delete lineItem

  $scope.deleteLineItems = (lineItemsToDelete) ->
    existingState = $scope.confirmDelete
    $scope.confirmDelete = false
    $scope.deleteLineItem lineItem for lineItem in lineItemsToDelete when lineItem.checked
    $scope.confirmDelete = existingState

  $scope.allBoxesChecked = ->
    checkedCount = $scope.filteredLineItems.reduce (count,lineItem) ->
      count + (if lineItem.checked then 1 else 0 )
    , 0
    checkedCount == $scope.filteredLineItems.length

  $scope.toggleAllCheckboxes = ->
    changeTo = !$scope.allBoxesChecked()
    lineItem.checked = changeTo for lineItem in $scope.filteredLineItems

  $scope.setSelectedUnitsVariant = (unitsProduct,unitsVariant) ->
    $scope.selectedUnitsProduct = unitsProduct
    $scope.selectedUnitsVariant = unitsVariant

  $scope.sumUnitValues = ->
    sum = $scope.filteredLineItems?.reduce (sum,lineItem) ->
      sum + lineItem.final_weight_volume
    , 0

  $scope.sumMaxUnitValues = ->
    sum = $scope.filteredLineItems?.reduce (sum,lineItem) ->
        sum + lineItem.max_quantity * lineItem.units_variant.unit_value
    , 0

  $scope.allFinalWeightVolumesPresent = ->
    for i,lineItem of $scope.filteredLineItems
      return false if !lineItem.hasOwnProperty('final_weight_volume') || !(lineItem.final_weight_volume > 0)
    true

  # How is this different to OptionValueNamer#name?
  # Should it be extracted to that class or VariantUnitManager?
  $scope.formattedValueWithUnitName = (value, unitsProduct, unitsVariant) ->
    # A Units Variant is an API object which holds unit properies of a variant
    if unitsProduct.hasOwnProperty("variant_unit") && (unitsProduct.variant_unit == "weight" || unitsProduct.variant_unit == "volume") && value > 0
      scale = VariantUnitManager.getScale(value, unitsProduct.variant_unit)
      Math.round(value/scale * 1000)/1000 + " " + VariantUnitManager.getUnitName(scale, unitsProduct.variant_unit)
    else
      ''

  $scope.fulfilled = (sumOfUnitValues) ->
    # A Units Variant is an API object which holds unit properies of a variant
    if $scope.selectedUnitsProduct.hasOwnProperty("group_buy_unit_size") && $scope.selectedUnitsProduct.group_buy_unit_size > 0 &&
      $scope.selectedUnitsProduct.hasOwnProperty("variant_unit") &&
      ( $scope.selectedUnitsProduct.variant_unit == "weight" || $scope.selectedUnitsProduct.variant_unit == "volume" )
        Math.round( sumOfUnitValues / $scope.selectedUnitsProduct.group_buy_unit_size * 1000)/1000
    else
      ''

  $scope.unitsVariantSelected = ->
    !angular.equals($scope.selectedUnitsVariant,{})

  $scope.weightAdjustedPrice = (lineItem) ->
    if lineItem.final_weight_volume > 0
      unit_value = lineItem.final_weight_volume / lineItem.quantity
      pristine_unit_value = LineItems.pristineByID[lineItem.id].final_weight_volume / LineItems.pristineByID[lineItem.id].quantity
      lineItem.price = LineItems.pristineByID[lineItem.id].price * (unit_value / pristine_unit_value)

  $scope.unitValueLessThanZero = (lineItem) ->
    if lineItem.units_variant.unit_value <= 0
      true
    else
      false

  $scope.updateOnQuantity = (lineItem) ->
    if lineItem.quantity > 0
      lineItem.final_weight_volume = LineItems.pristineByID[lineItem.id].final_weight_volume * lineItem.quantity / LineItems.pristineByID[lineItem.id].quantity
      $scope.weightAdjustedPrice(lineItem)

  $scope.resetFilters()
  $scope.refreshData()
