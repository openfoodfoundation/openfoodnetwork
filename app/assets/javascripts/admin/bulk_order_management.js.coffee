angular.module("ofn.admin").controller "AdminOrderMgmtCtrl", [
  "$scope", "$http", "$filter", "dataFetcher", "blankOption", "pendingChanges", "VariantUnitManager", "OptionValueNamer", "SpreeApiKey"
  ($scope, $http, $filter, dataFetcher, blankOption, pendingChanges, VariantUnitManager, OptionValueNamer, SpreeApiKey) ->
    $scope.loading = true

    $scope.initialiseVariables = ->
      start = daysFromToday -7
      end = daysFromToday 1
      $scope.lineItems = []
      $scope.filteredLineItems = []
      $scope.confirmDelete = true
      $scope.startDate = formatDate start
      $scope.endDate = formatDate end
      $scope.pendingChanges = pendingChanges
      $scope.quickSearch = ""
      $scope.bulkActions = [ { name: "Delete Selected", callback: $scope.deleteLineItems } ]
      $scope.selectedBulkAction = $scope.bulkActions[0]
      $scope.selectedUnitsProduct = {};
      $scope.selectedUnitsVariant = {};
      $scope.sharedResource = false
      $scope.predicate = ""
      $scope.reverse = false
      $scope.columns =
        order_no:     { name: "Order No.",    visible: false }
        full_name:    { name: "Name",         visible: true }
        email:        { name: "Email",        visible: false }
        phone:        { name: "Phone",        visible: false }
        order_date:   { name: "Order Date",   visible: true }
        producer:     { name: "Producer",     visible: true }
        order_cycle:  { name: "Order Cycle",  visible: false }
        hub:          { name: "Hub",          visible: false }
        variant:      { name: "Variant",      visible: true }
        quantity:     { name: "Quantity",     visible: true }
        max:          { name: "Max",          visible: true }
        unit_value:   { name: "Weight/Volume", visible: false }
        price:        { name: "Price",        visible: false }
    $scope.initialise = ->
      $scope.initialiseVariables()
      authorise_api_reponse = ""
      dataFetcher("/api/users/authorise_api?token=" + SpreeApiKey).then (data) ->
        authorise_api_reponse = data
        $scope.spree_api_key_ok = data.hasOwnProperty("success") and data["success"] == "Use of API Authorised"
        if $scope.spree_api_key_ok
          $http.defaults.headers.common["X-Spree-Token"] = SpreeApiKey
          dataFetcher("/api/enterprises/accessible?template=bulk_index&q[is_primary_producer_eq]=true").then (data) ->
            $scope.suppliers = $filter('orderBy')(data, 'name')
            $scope.suppliers.unshift blankOption()
            dataFetcher("/api/enterprises/accessible?template=bulk_index&q[sells_in][]=own&q[sells_in][]=any").then (data) ->
              $scope.distributors = $filter('orderBy')(data, 'name')
              $scope.distributors.unshift blankOption()
              ocFetcher = dataFetcher("/api/order_cycles/accessible?as=distributor&q[orders_close_at_gt]=#{formatDate(daysFromToday(-90))}").then (data) ->
                $scope.orderCycles = data
                $scope.orderCyclesByID = []
                $scope.orderCyclesByID[oc.id] = oc for oc in $scope.orderCycles
                $scope.orderCycles.unshift blankOption()
                $scope.fetchOrders()
              ocFetcher.then ->
                $scope.resetSelectFilters()
        else if authorise_api_reponse.hasOwnProperty("error")
          $scope.api_error_msg = authorise_api_reponse("error")
        else
          api_error_msg = "You don't have an API key yet. An attempt was made to generate one, but you are currently not authorised, please contact your site administrator for access."

    $scope.fetchOrders = ->
      $scope.loading = true
      dataFetcher("/admin/orders/managed?template=bulk_index;page=1;per_page=500;q[state_not_eq]=canceled;q[completed_at_not_null]=true;q[completed_at_gt]=#{$scope.startDate};q[completed_at_lt]=#{$scope.endDate}").then (data) ->
        $scope.resetOrders data
        $scope.loading = false

    $scope.resetOrders = (data) ->
      $scope.orders = data
      $scope.resetLineItems()
      pendingChanges.removeAll()

    $scope.resetLineItems = ->
      $scope.lineItems = $scope.orders.reduce (lineItems,order) ->
        orderWithoutLineItems = $scope.lineItemOrder order
        for i,line_item of order.line_items
          line_item.checked = false
          line_item.supplier = $scope.matchObject $scope.suppliers, line_item.supplier, null
          line_item.order = orderWithoutLineItems
        lineItems.concat order.line_items
      , []

    $scope.lineItemOrder = (order) ->
      lineItemOrder = angular.copy(order)
      delete lineItemOrder.line_items
      lineItemOrder.distributor = $scope.matchObject $scope.distributors, order.distributor, null
      lineItemOrder.order_cycle = $scope.matchObject $scope.orderCycles, order.order_cycle, null
      lineItemOrder

    $scope.matchObject = (list, testObject, noMatch) ->
      for i, object of list
        if angular.equals(object, testObject)
          return object
      return noMatch

    $scope.deleteLineItem = (lineItem) ->
      if ($scope.confirmDelete && confirm("Are you sure?")) || !$scope.confirmDelete
        $http(
          method: "DELETE"
          url: "/api/orders/" + lineItem.order.number + "/line_items/" + lineItem.id
        ).success (data) ->
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
        sum = sum + lineItem.quantity * lineItem.units_variant.unit_value
      , 0

    $scope.sumMaxUnitValues = ->
      sum = $scope.filteredLineItems.reduce (sum,lineItem) ->
        sum = sum + Math.max(lineItem.max_quantity,lineItem.quantity) * lineItem.units_variant.unit_value
      , 0

    $scope.allUnitValuesPresent = ->
      for i,lineItem of $scope.filteredLineItems
        return false if !lineItem.units_variant.hasOwnProperty('unit_value') || !(lineItem.units_variant.unit_value > 0)
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

    $scope.resetSelectFilters = ->
      $scope.distributorFilter = $scope.distributors[0].id
      $scope.supplierFilter = $scope.suppliers[0].id
      $scope.orderCycleFilter = $scope.orderCycles[0].id
      $scope.quickSearch = ""

    $scope.weightAdjustedPrice = (lineItem, oldValue) ->
      if oldValue <= 0
        oldValue = lineItem.units_variant.unit_value
      if lineItem.unit_value <= 0
        lineItem.unit_value = lineItem.units_variant.unit_value
      lineItem.price = lineItem.price * lineItem.unit_value / oldValue
      #$scope.bulk_order_form.line_item.price.$setViewValue($scope.bulk_order_form.line_item.price.$viewValue)

    $scope.unitValueLessThanZero = (lineItem) ->
      if lineItem.units_variant.unit_value <= 0
        true
      else
        false

    $scope.$watch "orderCycleFilter", (newVal, oldVal) ->
      unless $scope.orderCycleFilter == "0" || angular.equals(newVal, oldVal)
        $scope.startDate = $scope.orderCyclesByID[$scope.orderCycleFilter].first_order
        $scope.endDate = $scope.orderCyclesByID[$scope.orderCycleFilter].last_order
]

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

twoDigitNumber = (number) ->
  twoDigits =  "" + number
  twoDigits = ("0" + number) if number < 10
  twoDigits
