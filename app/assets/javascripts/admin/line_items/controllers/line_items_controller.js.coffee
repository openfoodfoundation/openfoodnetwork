angular.module("admin.lineItems").controller 'LineItemsCtrl', ($scope, $timeout, $http, $q, StatusMessage, Columns, SortOptions, Dereferencer, Orders, LineItems, Enterprises, OrderCycles, VariantUnitManager, RequestMonitor) ->
  $scope.initialized = false
  $scope.RequestMonitor = RequestMonitor
  $scope.line_items = LineItems.all
  $scope.confirmDelete = true
  $scope.bulkActions = [ { name: t("admin.orders.bulk_management.actions_delete"), callback: 'deleteLineItems' } ]
  $scope.selectedUnitsProduct = {}
  $scope.selectedUnitsVariant = {}
  $scope.sharedResource = false
  $scope.columns = Columns.columns
  $scope.sorting = SortOptions
  $scope.pagination = LineItems.pagination
  $scope.per_page_options = [
    {id: 15, name: t('js.admin.orders.index.per_page', results: 15)},
    {id: 50, name: t('js.admin.orders.index.per_page', results: 50)},
    {id: 100, name: t('js.admin.orders.index.per_page', results: 100)}
  ]
  $scope.page = 1
  $scope.per_page = $scope.per_page_options[0].id
  searchThrough = ["order_distributor_name",
    "order_bill_address_phone",
    "order_bill_address_firstname",
    "order_bill_address_lastname",
    "variant_product_supplier_name",
    "order_email",
    "order_number",
    "product_name"].join("_or_") + "_cont"

  $scope.confirmRefresh = ->
    LineItems.allSaved() || confirm(t("unsaved_changes_warning"))

  $scope.resetFilters = ->
    $scope.distributorFilter = ''
    $scope.supplierFilter = ''
    $scope.orderCycleFilter = ''
    $scope.query = ''
    $scope.startDate = undefined
    $scope.endDate = undefined
    event = new CustomEvent('flatpickr:clear')
    window.dispatchEvent(event)

  $scope.resetSelectFilters = ->
    $scope.resetFilters()
    $scope.refreshData()

  $scope.fetchResults = ->
    # creates indirection in order to factorize the code between orders and bulk orders
    # used in app/views/admin/shared/_angular_per_page_controls.html.haml
    $scope.refreshData()

  $scope.refreshData = ->
    return "cancel" unless $scope.confirmRefresh()

    $scope.loadLineItems()

    unless $scope.initialized
      $scope.loadAssociatedData()

    $scope.dereferenceLoadedData()

  $scope.loadOrders = ->
    RequestMonitor.load $scope.orders = Orders.index(
      "q[id_in][]": $scope.line_items.map((line_item) -> line_item.order.id)
    )

  $scope.loadLineItems = ->
    [formattedStartDate, formattedEndDate] = $scope.formatDates($scope.startDate, $scope.endDate)

    RequestMonitor.load LineItems.index(
      "q[#{searchThrough}]": $scope.query,
      "q[order_state_not_eq]": "canceled",
      "q[order_shipment_state_not_eq]": "shipped",
      "q[order_completed_at_not_null]": "true",
      "q[order_distributor_id_eq]": $scope.distributorFilter,
      "q[variant_product_supplier_id_eq]": $scope.supplierFilter,
      "q[order_order_cycle_id_eq]": $scope.orderCycleFilter,
      "q[order_completed_at_gteq]": if formattedStartDate then formattedStartDate else undefined,
      "q[order_completed_at_lt]": if formattedEndDate then formattedEndDate else undefined,
      "page": $scope.page,
      "per_page": $scope.per_page
    )

  $scope.formatDates = (startDate, endDate) ->
    formattedStartDate = moment(startDate).format('YYYY-MM-DD') if startDate
    formattedEndDate = moment(endDate).add(1,'day').format('YYYY-MM-DD') if endDate
    return [formattedStartDate, formattedEndDate]

  $scope.loadAssociatedData = ->
    RequestMonitor.load $scope.distributors = Enterprises.index(action: "visible", ams_prefix: "basic", "q[sells_in][]": ["own", "any"])
    RequestMonitor.load $scope.orderCycles = OrderCycles.index(ams_prefix: "basic", as: "distributor", "q[orders_close_at_gt]": "#{moment().subtract(90,'days').format()}")
    RequestMonitor.load $scope.suppliers = Enterprises.index(action: "visible", ams_prefix: "basic", "q[is_primary_producer_eq]": "true")

  $scope.dereferenceLoadedData = ->
    RequestMonitor.load $q.all([$scope.distributors.$promise, $scope.orderCycles.$promise, $scope.suppliers.$promise, $scope.line_items.$promise]).then ->
      Dereferencer.dereferenceAttr $scope.line_items, "supplier", Enterprises.byID
      $scope.loadOrders()
      RequestMonitor.load $q.all([$scope.orders.$promise]).then ->
        Dereferencer.dereferenceAttr $scope.line_items, "order", Orders.byID  
        Dereferencer.dereferenceAttr $scope.orders, "distributor", Enterprises.byID
        Dereferencer.dereferenceAttr $scope.orders, "order_cycle", OrderCycles.byID
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

  $scope.cancelOrder = (order, sendEmailCancellation) ->
    return $http(
      method: 'GET'
      url: "/admin/orders/#{order.number}/fire?e=cancel&send_cancellation_email=#{sendEmailCancellation}")
  
  $scope.deleteLineItem = (lineItem) ->
    if lineItem.order.item_count == 1
      ofnCancelOrderAlert((confirm, sendEmailCancellation) ->
        if confirm
          $scope.cancelOrder(lineItem.order, sendEmailCancellation).then(->
            $scope.refreshData()
          )
        else
          $scope.refreshData()
      , "js.admin.deleting_item_will_cancel_order")
    else if ($scope.confirmDelete && confirm(t "are_you_sure")) || !$scope.confirmDelete
      LineItems.delete(lineItem, () -> $scope.refreshData())

  $scope.deleteLineItems = (lineItems) ->
    lineItemsToDelete = lineItems.filter (item) -> item.checked
    willCancelOrders = false
    itemsPerOrder = new Map()
    for item in lineItemsToDelete
      { order } = item
      if itemsPerOrder.has(order)
        itemsPerOrder.get(order).push(item)
      else
        itemsPerOrder.set(order, [item])
      willCancelOrders = true if (order.item_count == itemsPerOrder.get(order).length)

    if willCancelOrders
      ofnCancelOrderAlert((confirm, sendEmailCancellation) ->
        if confirm
          itemsPerOrder.forEach (items, order) =>
            if order.item_count == items.length
              $scope.cancelOrder(order, sendEmailCancellation).then(-> $scope.refreshData())
            else
              Promise.all(LineItems.delete(item) for item in items).then(-> $scope.refreshData())
      , "js.admin.deleting_item_will_cancel_order")   
    else
      ofnDeleteLineItemsAlert(() ->
        Promise.all(LineItems.delete(item) for item in lineItemsToDelete).then(-> $scope.refreshData())
      , lineItemsToDelete.length)

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

  $scope.getLineItemScale = (lineItem) ->
    if lineItem.units_product && lineItem.units_variant && (lineItem.units_product.variant_unit == "weight" || lineItem.units_product.variant_unit == "volume") 
      lineItem.units_product.variant_unit_scale
    else
      1

  $scope.sumUnitValues = ->
    sum = $scope.filteredLineItems?.reduce (sum, lineItem) ->
      if lineItem.units_product.variant_unit == "items"
        sum + lineItem.quantity
      else
        sum + $scope.roundToThreeDecimals(lineItem.final_weight_volume / $scope.getLineItemScale(lineItem))
    , 0

  $scope.sumMaxUnitValues = ->
    sum = $scope.filteredLineItems?.reduce (sum,lineItem) ->
      if lineItem.units_product.variant_unit == "items"
        sum + lineItem.max_quantity
      else
        sum + lineItem.max_quantity * $scope.roundToThreeDecimals(lineItem.units_variant.unit_value / $scope.getLineItemScale(lineItem))
    , 0

  $scope.roundToThreeDecimals = (value) ->
    Math.round(value * 1000) / 1000

  $scope.allFinalWeightVolumesPresent = ->
    for i,lineItem of $scope.filteredLineItems
      return false if !lineItem.hasOwnProperty('final_weight_volume') || !(lineItem.final_weight_volume > 0)
    true

  $scope.getScale = (unitsProduct, unitsVariant) ->
    if unitsProduct.hasOwnProperty("variant_unit") && (unitsProduct.variant_unit == "weight" || unitsProduct.variant_unit == "volume")
      unitsProduct.variant_unit_scale
    else if unitsProduct.hasOwnProperty("variant_unit") && unitsProduct.variant_unit == "items"
      1
    else
      null

  $scope.getFormattedValueWithUnitName = (value, unitsProduct, unitsVariant, scale) ->
    unit_name = VariantUnitManager.getUnitName(scale, unitsProduct.variant_unit)
    $scope.roundToThreeDecimals(value) + " " + unit_name

  $scope.getGroupBySizeFormattedValueWithUnitName = (value, unitsProduct, unitsVariant) ->
    scale = $scope.getScale(unitsProduct, unitsVariant)
    if scale && value
      value = value / scale if scale != 28.35 && scale != 1 && scale != 453.6 # divide by scale if not smallest unit
      $scope.getFormattedValueWithUnitName(value, unitsProduct, unitsVariant, scale)
    else
      ''

  $scope.formattedValueWithUnitName = (value, unitsProduct, unitsVariant) ->
    scale = $scope.getScale(unitsProduct, unitsVariant)
    if scale
      $scope.getFormattedValueWithUnitName(value, unitsProduct, unitsVariant, scale)
    else 
      ''

  $scope.fulfilled = (sumOfUnitValues) ->
    # A Units Variant is an API object which holds unit properies of a variant
    if $scope.selectedUnitsProduct.hasOwnProperty("group_buy_unit_size")&& $scope.selectedUnitsProduct.group_buy_unit_size > 0 &&
      $scope.selectedUnitsProduct.hasOwnProperty("variant_unit")
        if $scope.selectedUnitsProduct.variant_unit == "weight" || $scope.selectedUnitsProduct.variant_unit == "volume"
          scale = $scope.selectedUnitsProduct.variant_unit_scale
          sumOfUnitValues = sumOfUnitValues * scale unless scale == 28.35 || scale == 453.6
        $scope.roundToThreeDecimals(sumOfUnitValues / $scope.selectedUnitsProduct.group_buy_unit_size)
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

  $scope.changePage = (newPage) ->
    $scope.page = newPage
    $scope.refreshData()

  $scope.resetSelectFilters()
