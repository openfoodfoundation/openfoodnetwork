orderManagementModule = angular.module("ofn.bulk_order_management", ["ofn.shared_services", "ofn.shared_directives"])

orderManagementModule.config [
  "$httpProvider"
  (provider) ->
    provider.defaults.headers.common["X-CSRF-Token"] = $("meta[name=csrf-token]").attr("content")
]

orderManagementModule.value "blankOption", ->
  { id: "", name: "All" }

orderManagementModule.directive "ofnLineItemUpdAttr", [
  "switchClass", "pendingChanges"
  (switchClass, pendingChanges) ->
    require: "ngModel"
    link: (scope, element, attrs, ngModel) ->
      attrName = attrs.ofnLineItemUpdAttr
      element.dbValue = scope.$eval(attrs.ngModel)
      scope.$watch ->
        scope.$eval(attrs.ngModel)
      , (value) ->
        if ngModel.$dirty
          if value == element.dbValue
            pendingChanges.remove(scope.line_item.id, attrName)
            switchClass( element, "", ["update-pending", "update-error", "update-success"], false )
          else
            changeObj =
              lineItem: scope.line_item
              element: element
              attrName: attrName
              url: "/api/orders/#{scope.line_item.order.number}/line_items/#{scope.line_item.id}?line_item[#{attrName}]=#{value}"
            pendingChanges.add(scope.line_item.id, attrName, changeObj)
            switchClass( element, "update-pending", ["update-error", "update-success"], false )
]

orderManagementModule.directive "ofnConfirmChange", [
  "pendingChanges", "$compile", "$q"
  (pendingChanges, $compile, $q) ->
    require: "ngModel"
    link: (scope, element, attrs, ngModel) ->
      modelName = attrs.ofnConfirmChange
      template = "<div id='dialog-div' style='padding: 10px'><h6>Unsaved changes currently exist, save now or ignore?</h6></div>"
      dialogDiv = $compile(template)(scope)
      ngModel.$parsers.unshift (newValue) ->
        if pendingChanges.changeCount(pendingChanges.pendingChanges) > 0
          dialogDiv.dialog
            dialogClass: "no-close"
            resizable: false
            height: 140
            modal: true
            buttons:
              "SAVE": ->
                dialogDiv = $(this)
                $q.all(pendingChanges.submitAll()).then ->
                  scope.$evalAsync ->
                    scope.fetchOrders()
                  dialogDiv.dialog "close"
              "IGNORE": ->
                scope.$evalAsync ->
                  scope.fetchOrders()
                $(this).dialog "close"
                scope.$apply()
          dialogDiv.dialog "open"
        else
          scope.$evalAsync ->
            scope.fetchOrders()
        newValue
]

orderManagementModule.factory "pendingChanges",[
  "dataSubmitter"
  (dataSubmitter) ->
    pendingChanges: {}

    add: (id, attrName, changeObj) ->
      this.pendingChanges["#{id}"] = {} unless this.pendingChanges.hasOwnProperty("#{id}")
      this.pendingChanges["#{id}"]["#{attrName}"] = changeObj

    removeAll: ->
      this.pendingChanges = {}

    remove: (id, attrName) ->
      if this.pendingChanges.hasOwnProperty("#{id}")
        delete this.pendingChanges["#{id}"]["#{attrName}"]
        delete this.pendingChanges["#{id}"] if this.changeCount( this.pendingChanges["#{id}"] ) < 1

    submitAll: ->
      all = []
      for id,lineItem of this.pendingChanges
        for attrName,changeObj of lineItem
          all.push this.submit(id, attrName, changeObj)
      all

    submit: (id, attrName, change) ->
      factory = this
      dataSubmitter(change).then (data) ->
        factory.remove id, attrName
        change.element.dbValue = data["#{attrName}"]

    changeCount: (lineItem) ->
      Object.keys(lineItem).length
]


orderManagementModule.controller "AdminOrderMgmtCtrl", [
  "$scope", "$http", "dataFetcher", "blankOption", "pendingChanges"
  ($scope, $http, dataFetcher, blankOption, pendingChanges) ->

    $scope.initialiseVariables = ->
      now = new Date
      start = new Date( now.getTime() - ( 7 * (1440 * 60 * 1000) ) - (now.getTime() - now.getTimezoneOffset() * 60 * 1000) % (1440 * 60 * 1000) )
      end = new Date( now.getTime() - (now.getTime() - now.getTimezoneOffset() * 60 * 1000) % (1440 * 60 * 1000) + ( 1 * ( 1440 * 60 * 1000 ) ) )
      $scope.lineItems = []
      $scope.filteredLineItems = []
      $scope.confirmDelete = true
      $scope.startDate = formatDate start
      $scope.endDate = formatDate end
      $scope.pendingChanges = pendingChanges
      $scope.quickSearch = ""
      $scope.bulkActions = [ { name: "Delete", callback: $scope.deleteSelected } ]
      $scope.selectedBulkAction = $scope.bulkActions[0]
      $scope.selectedUnitsVariant = {};

    $scope.initialise = (spree_api_key) ->
      $scope.initialiseVariables()
      authorise_api_reponse = ""
      dataFetcher("/api/users/authorise_api?token=" + spree_api_key).then (data) ->
        authorise_api_reponse = data
        $scope.spree_api_key_ok = data.hasOwnProperty("success") and data["success"] == "Use of API Authorised"
        if $scope.spree_api_key_ok
          $http.defaults.headers.common["X-Spree-Token"] = spree_api_key
          dataFetcher("/api/enterprises/managed?template=bulk_index&q[is_primary_producer_eq]=true").then (data) ->
            $scope.suppliers = data
            $scope.suppliers.unshift blankOption()
            $scope.supplierFilter = $scope.suppliers[0]
            dataFetcher("/api/enterprises/managed?template=bulk_index&q[is_distributor_eq]=true").then (data) ->
              $scope.distributors = data
              $scope.distributors.unshift blankOption()
              $scope.distributorFilter = $scope.distributors[0]
              dataFetcher("/api/order_cycles/managed").then (data) ->
                $scope.orderCycles = data
                $scope.matchOrderCycleEnterprises orderCycle for orderCycle in $scope.orderCycles
                $scope.orderCycles.unshift blankOption()
                $scope.orderCycleFilter = $scope.orderCycles[0]
                $scope.fetchOrders()
        else if authorise_api_reponse.hasOwnProperty("error")
          $scope.api_error_msg = authorise_api_reponse("error")
        else
          api_error_msg = "You don't have an API key yet. An attempt was made to generate one, but you are currently not authorised, please contact your site administrator for access."

    $scope.fetchOrders = ->
      $scope.loading = true
      dataFetcher("/api/orders?template=bulk_index&q[completed_at_not_null]=true&q[completed_at_gt]=#{$scope.startDate}&q[completed_at_lt]=#{$scope.endDate}").then (data) ->
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

    $scope.matchOrderCycleEnterprises = (orderCycle) ->
      for i,distributor of orderCycle.distributors
        orderCycle.distributors[i] = $scope.matchObject $scope.distributors, distributor, null
      for i,supplier of orderCycle.suppliers
        orderCycle.suppliers[i] = $scope.matchObject $scope.suppliers, supplier, null

    $scope.matchObject = (list, testObject, noMatch) ->
      for i, object of list
        if angular.equals(object, testObject)
          return object
        else
      return noMatch

    $scope.deleteLineItem = (lineItem) ->
      if ($scope.confirmDelete && confirm("Are you sure?")) || !$scope.confirmDelete
        $http(
          method: "DELETE"
          url: "/api/orders/" + lineItem.order.number + "/line_items/" + lineItem.id
        ).success (data) ->
          $scope.lineItems.splice $scope.lineItems.indexOf(lineItem), 1

    $scope.deleteSelected = ->
      existingState = $scope.confirmDelete
      $scope.confirmDelete = false
      $scope.deleteLineItem lineItem for lineItem in $scope.lineItems when lineItem.checked
      $scope.confirmDelete = existingState

    $scope.allBoxesChecked = ->
      checkedCount = $scope.lineItems.reduce (count,lineItem) ->
        count + (if lineItem.checked then 1 else 0 )
      , 0
      checkedCount == $scope.lineItems.length

    $scope.toggleAllCheckboxes = ->
      changeTo = !$scope.allBoxesChecked()
      lineItem.checked = changeTo for lineItem in $scope.lineItems

    $scope.setSelectedUnitsVariant = (unitsVariant) ->
      $scope.selectedUnitsVariant = unitsVariant

    $scope.sumUnitValues = (lineItems) ->
      sum = lineItems.reduce (sum,lineItem) ->
        sum = sum + lineItem.quantity * lineItem.units_variant.unit_value
      , 0

    $scope.getScale = (value, unitType) ->
      scaledValue = null
      validScales = []
      unitScales =
        'weight': [1.0, 1000.0, 1000000.0]
        'volume': [0.001, 1.0, 1000000.0]

      validScales.unshift scale for scale in unitScales[unitType] when value/scale >= 1
      if validScales.length > 0
        validScales[0]
      else
        unitScales[unitType][0]

    $scope.getUnitName = (scale, unitType) ->
      unitNames =
        'weight': {1.0: 'g', 1000.0: 'kg', 1000000.0: 'T'}
        'volume': {0.001: 'mL', 1.0: 'L',  1000000.0: 'ML'}
      unitNames[unitType][scale]

    $scope.formattedValueWithUnitName = (value, unitsVariant) ->
      # A Units Variant is an API object which holds unit properies of a variant
      if unitsVariant.hasOwnProperty("variant_unit") && unitsVariant.variant_unit == "weight" || unitsVariant.variant_unit == "volume"
        scale = $scope.getScale(value, unitsVariant.variant_unit)
        Math.round(value/scale * 1000)/1000 + " " + $scope.getUnitName(scale,unitsVariant.variant_unit)
      else
        ''

    $scope.fulfilled = ->
      # A Units Variant is an API object which holds unit properies of a variant
      if $scope.selectedUnitsVariant.hasOwnProperty("variant_unit") && ( $scope.selectedUnitsVariant.variant_unit == "weight" || $scope.selectedUnitsVariant.variant_unit == "volume" )
        Math.round( $scope.sumUnitValues( $scope.filteredLineItems ) / $scope.selectedUnitsVariant.group_buy_unit_size * 1000)/1000
      else
        ''

    $scope.unitsVariantSelected = ->
      angular.equals($scope.selectedUnitsVariant,{})
]

orderManagementModule.filter "selectFilter", [
  "blankOption"
  (blankOption) ->
    return (lineItems,selectedSupplier,selectedDistributor,selectedOrderCycle,selectedUnitsVariant) ->
      filtered = []
      filtered.push lineItem for lineItem in lineItems when (angular.equals(selectedSupplier,blankOption()) || lineItem.supplier == selectedSupplier) &&
        (angular.equals(selectedDistributor,blankOption()) || lineItem.order.distributor == selectedDistributor) &&
        (angular.equals(selectedOrderCycle,blankOption()) || lineItem.order.order_cycle == selectedOrderCycle) &&
        (angular.equals(selectedUnitsVariant,{}) || lineItem.units_variant.unit_text == selectedUnitsVariant.unit_text )
      filtered
]

orderManagementModule.factory "dataSubmitter", [
  "$http", "$q", "switchClass"
  ($http, $q, switchClass) ->
    return (changeObj) ->
      deferred = $q.defer()
      $http.put(changeObj.url).success((data) ->
        switchClass changeObj.element, "update-success", ["update-pending", "update-error"], 3000
        deferred.resolve data
      ).error ->
        switchClass changeObj.element, "update-error", ["update-pending", "update-success"], false
        deferred.reject()
      deferred.promise
]

orderManagementModule.factory "switchClass", [
  "$timeout"
  ($timeout) ->
    return (element,classToAdd,removeClasses,timeout) ->
      $timeout.cancel element.timeout if element.timeout
      element.removeClass className for className in removeClasses
      element.addClass classToAdd
      intRegex = /^\d+$/
      if timeout && intRegex.test(timeout)
        element.timeout = $timeout(->
          element.removeClass classToAdd
        , timeout, true)
]

formatDate = (date) ->
  year = date.getFullYear()
  month = twoDigitNumber date.getMonth() + 1
  day = twoDigitNumber date.getDate()
  hours = twoDigitNumber date.getHours()
  mins = twoDigitNumber date.getMinutes()
  secs = twoDigitNumber date.getSeconds()
  return year + "-" + month + "-" + day + " " + hours + ":" + mins + ":" + secs

twoDigitNumber = (number) ->
  twoDigits =  "" + number
  twoDigits = ("0" + number) if number < 10
  twoDigits