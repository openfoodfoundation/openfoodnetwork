Darkswarm.controller "ShopVariantCtrl", ($scope, $modal, Cart) ->
  $scope.$watchGroup [
    'variant.line_item.quantity',
    'variant.line_item.max_quantity'
  ], (new_value, old_value) ->
    return if old_value[0] == null && new_value[0] == null
    Cart.adjust($scope.variant.line_item)

  $scope.variant.line_item.quantity ||= 0

  $scope.$watch "variant.line_item.quantity", ->
    item = $scope.variant.line_item
    if item.quantity > $scope.available()
      item.quantity = $scope.available()

  $scope.$watch "variant.line_item.max_quantity", ->
    item = $scope.variant.line_item
    if item.max_quantity > $scope.available()
      item.max_quantity = $scope.available()

  if $scope.variant.product.group_buy
    $scope.$watch "variant.line_item.quantity", ->
      item = $scope.variant.line_item
      if item.quantity < 1 || item.max_quantity < item.quantity
        item.max_quantity = item.quantity

    $scope.$watch "variant.line_item.max_quantity", ->
      item = $scope.variant.line_item
      if item.max_quantity < item.quantity
        item.quantity = item.max_quantity

  $scope.quantity = ->
    $scope.variant.line_item.quantity || 0

  $scope.maxQuantity = ->
    $scope.variant.line_item.max_quantity || $scope.sanitizedQuantity()

  $scope.sanitizedQuantity = ->
    Math.max(0, Math.min($scope.quantity(), $scope.available()))

  $scope.sanitizedMaxQuantity = ->
    Math.max($scope.sanitizedQuantity(), Math.min($scope.maxQuantity(), $scope.available()))

  $scope.add = (quantity) ->
    item = $scope.variant.line_item
    item.quantity = $scope.sanitizedQuantity() + quantity

  $scope.addMax = (quantity) ->
    item = $scope.variant.line_item
    item.max_quantity = $scope.sanitizedMaxQuantity() + quantity

  $scope.canAdd = (quantity) ->
    wantedQuantity = $scope.sanitizedQuantity() + quantity
    $scope.quantityValid(wantedQuantity)

  $scope.canAddMax = (quantity) ->
    variant = $scope.variant
    wantedQuantity = $scope.sanitizedMaxQuantity() + quantity
    $scope.quantityValid(wantedQuantity) && variant.line_item.quantity > 0

  $scope.available = ->
    variant = $scope.variant
    variant.on_demand && Infinity || variant.on_hand

  $scope.quantityValid = (quantity) ->
    variant = $scope.variant
    minimum = 0
    maximum = variant.on_demand && Infinity || variant.on_hand
    quantity >= minimum && quantity <= maximum

  $scope.addBulk = (quantity) ->
    $scope.add(quantity)
    $modal.open(templateUrl: "bulk_buy_modal.html", scope: $scope, windowClass: "product-bulk-modal")
