angular.module("admin.lineItems").controller 'LineItemsCtrl', ($scope, $timeout, $http, $q, StatusMessage, Columns, Dereferencer, Orders, LineItems, Enterprises, OrderCycles, VariantUnitManager, RequestMonitor) ->
  $scope.initialized = false
  $scope.RequestMonitor = RequestMonitor
  $scope.filteredLineItems = []
  $scope.confirmDelete = true
  $scope.startDate = formatDate daysFromToday -7
  $scope.endDate = formatDate daysFromToday 1
  $scope.bulkActions = [ { name: t("admin.orders.bulk_management.actions_delete"), callback: 'deleteLineItems' } ]
  $scope.selectedUnitsProduct = {}
  $scope.selectedUnitsVariant = {}
  $scope.sharedResource = false
  $scope.columns = Columns.columns

  $scope.confirmRefresh = ->
    LineItems.allSaved() || confirm(t("unsaved_changes_warning"))

  $scope.resetSelectFilters = ->
    $scope.distributorFilter = 0
    $scope.supplierFilter = 0
    $scope.orderCycleFilter = 0
    $scope.quickSearch = ""

  $scope.refreshData = ->
    unless !$scope.orderCycleFilter? || $scope.orderCycleFilter == 0
      $scope.startDate = OrderCycles.byID[$scope.orderCycleFilter].first_order
      $scope.endDate = OrderCycles.byID[$scope.orderCycleFilter].last_order

    RequestMonitor.load $scope.orders = Orders.index("q[state_not_eq]": "canceled", "q[completed_at_not_null]": "true", "q[completed_at_gt]": "#{parseDate($scope.startDate)}", "q[completed_at_lt]": "#{parseDate($scope.endDate)}")
    RequestMonitor.load $scope.lineItems = LineItems.index("q[order][state_not_eq]": "canceled", "q[order][completed_at_not_null]": "true", "q[order][completed_at_gt]": "#{parseDate($scope.startDate)}", "q[order][completed_at_lt]": "#{parseDate($scope.endDate)}")

    unless $scope.initialized
      RequestMonitor.load $scope.distributors = Enterprises.index(action: "visible", ams_prefix: "basic", "q[sells_in][]": ["own", "any"])
      RequestMonitor.load $scope.orderCycles = OrderCycles.index(ams_prefix: "basic", as: "distributor", "q[orders_close_at_gt]": "#{daysFromToday(-90)}")
      RequestMonitor.load $scope.suppliers = Enterprises.index(action: "visible", ams_prefix: "basic", "q[is_primary_producer_eq]": "true")

    RequestMonitor.load $q.all([$scope.orders.$promise, $scope.distributors.$promise, $scope.orderCycles.$promise]).then ->
      Dereferencer.dereferenceAttr $scope.orders, "distributor", Enterprises.byID
      Dereferencer.dereferenceAttr $scope.orders, "order_cycle", OrderCycles.byID

    RequestMonitor.load $q.all([$scope.orders.$promise, $scope.suppliers.$promise, $scope.lineItems.$promise]).then ->
      Dereferencer.dereferenceAttr $scope.lineItems, "supplier", Enterprises.byID
      Dereferencer.dereferenceAttr $scope.lineItems, "order", Orders.byID
      $scope.bulk_order_form.$setPristine()
      StatusMessage.clear()
      unless $scope.initialized
        $scope.initialized = true
        $timeout ->
          $scope.resetSelectFilters()

  $scope.refreshData()

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
      LineItems.delete lineItem, =>
        $scope.lineItems.splice $scope.lineItems.indexOf(lineItem), 1

  $scope.deleteLineItems = (lineItems) ->
    existingState = $scope.confirmDelete
    $scope.confirmDelete = false
    $scope.deleteLineItem lineItem for lineItem in lineItems when lineItem.checked
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
    sum = $scope.filteredLineItems.reduce (sum,lineItem) ->
      sum + lineItem.final_weight_volume
    , 0

  $scope.sumMaxUnitValues = ->
    sum = $scope.filteredLineItems.reduce (sum,lineItem) ->
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

daysFromToday = (days) ->
  now = new Date
  now.setHours(0)
  now.setMinutes(0)
  now.setSeconds(0)
  now.setDate( now.getDate() + days )
  now

formatDate = (date) ->
  year = date.getFullYear()
  month = twoDigitNumber date.getMonth() + 1
  day = twoDigitNumber date.getDate()
  return year + "-" + month + "-" + day

formatTime = (date) ->
  hours = twoDigitNumber date.getHours()
  mins = twoDigitNumber date.getMinutes()
  secs = twoDigitNumber date.getSeconds()
  return hours + ":" + mins + ":" + secs

parseDate = (dateString) ->
  new Date(Date.parse(dateString))

twoDigitNumber = (number) ->
  twoDigits =  "" + number
  twoDigits = ("0" + number) if number < 10
  twoDigits
