orderManagementModule = angular.module("ofn.bulk_order_management", ["ofn.shared_services"])

orderManagementModule.config [
  "$httpProvider"
  (provider) ->
    provider.defaults.headers.common["X-CSRF-Token"] = $("meta[name=csrf-token]").attr("content")
]

orderManagementModule.value "blankEnterprise", ->
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

orderManagementModule.factory "pendingChanges",[
  "dataSubmitter"
  (dataSubmitter) ->
    pendingChanges: {}

    add: (id, attrName, changeObj) ->
      this.pendingChanges["#{id}"] = {} unless this.pendingChanges.hasOwnProperty("#{id}")
      this.pendingChanges["#{id}"]["#{attrName}"] = changeObj

    remove: (id, attrName) ->
      if this.pendingChanges.hasOwnProperty("#{id}")
        delete this.pendingChanges["#{id}"]["#{attrName}"]
        delete this.pendingChanges["#{id}"] if this.changeCount( this.pendingChanges["#{id}"] ) < 1

    submitAll: ->
      for id,lineItem of this.pendingChanges
        for attrName,changeObj of lineItem
          this.submit id, attrName, changeObj

    submit: (id, attrName, change) ->
      factory = this
      dataSubmitter(change).then (data) ->
        factory.remove id, attrName
        change.element.dbValue = data["#{attrName}"]

    changeCount: (lineItem) ->
      Object.keys(lineItem).length
]


orderManagementModule.controller "AdminOrderMgmtCtrl", [
  "$scope", "$http", "dataFetcher", "blankEnterprise", "pendingChanges"
  ($scope, $http, dataFetcher, blankEnterprise, pendingChanges) ->

    $scope.lineItems = []
    $scope.confirmDelete = true
    $scope.pendingChanges = pendingChanges

    $scope.initialise = (spree_api_key) ->
      authorise_api_reponse = ""
      dataFetcher("/api/users/authorise_api?token=" + spree_api_key).then (data) ->
        authorise_api_reponse = data
        $scope.spree_api_key_ok = data.hasOwnProperty("success") and data["success"] == "Use of API Authorised"
        if $scope.spree_api_key_ok
          $http.defaults.headers.common["X-Spree-Token"] = spree_api_key
          dataFetcher("/api/enterprises/managed?template=bulk_index&q[is_primary_producer_eq]=true").then (data) ->
            $scope.suppliers = data
            $scope.suppliers.unshift blankEnterprise()
            $scope.supplierFilter = $scope.suppliers[0]
            dataFetcher("/api/enterprises/managed?template=bulk_index&q[is_distributor_eq]=true").then (data) ->
              $scope.distributors = data
              $scope.distributors.unshift blankEnterprise()
              $scope.distributorFilter = $scope.distributors[0]
              $scope.fetchOrders()
        else if authorise_api_reponse.hasOwnProperty("error")
          $scope.api_error_msg = authorise_api_reponse("error")
        else
          api_error_msg = "You don't have an API key yet. An attempt was made to generate one, but you are currently not authorised, please contact your site administrator for access."

    $scope.fetchOrders = ->
      dataFetcher("/api/orders?template=bulk_index").then (data) ->
        $scope.resetOrders data

    $scope.resetOrders = (data) ->
      $scope.orders = data
      $scope.resetLineItems()
      $scope.matchDistributor order for order in $scope.orders

    $scope.resetLineItems = ->
      $scope.lineItems = $scope.orders.reduce (lineItems,order) ->
        for i,line_item of order.line_items
          $scope.matchSupplier line_item
          line_item.order = order
        lineItems.concat order.line_items
      , []

    $scope.matchSupplier = (line_item) ->
      for i, supplier of $scope.suppliers
        if angular.equals(supplier, line_item.supplier)
          line_item.supplier = supplier
          break

    $scope.matchDistributor = (order) ->
      for i, distributor of $scope.distributors
        if angular.equals(distributor, order.distributor)
          order.distributor = distributor
          break

    $scope.deleteLineItem = (lineItem) ->
      if ($scope.confirmDelete && confirm("Are you sure?")) || !$scope.confirmDelete
        $http(
          method: "DELETE"
          url: "/api/orders/" + lineItem.order.number + "/line_items/" + lineItem.id
        ).success (data) ->
          $scope.lineItems.splice $scope.lineItems.indexOf(lineItem), 1
          lineItem.order.line_items.splice lineItem.order.line_items.indexOf(lineItem), 1
]

orderManagementModule.filter "selectFilter", [
  "blankEnterprise"
  (blankEnterprise) ->
    return (lineItems,selectedSupplier,selectedDistributor) ->
      filtered = []
      filtered.push line_item for line_item in lineItems when (angular.equals(selectedSupplier,blankEnterprise()) || line_item.supplier == selectedSupplier) &&
        (angular.equals(selectedDistributor,blankEnterprise()) || line_item.order.distributor == selectedDistributor)
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
