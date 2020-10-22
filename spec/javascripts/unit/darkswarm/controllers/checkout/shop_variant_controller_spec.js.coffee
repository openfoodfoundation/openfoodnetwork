describe "ShopVariantCtrl", ->
  ctrl = null
  scope = null

  beforeEach ->
    module 'Darkswarm'
    scope =
      $watchGroup: ->
      variant: {
        on_demand: true
        product: {group_buy: false}
        line_item: {
          quantity: 0
          max_quantity: 0
        }
      }

    inject ($controller, $modal)->
      ctrl = $controller 'ShopVariantCtrl', {$scope: scope, $modal: $modal, Cart: null}

  it "adds an item to the cart", ->
    scope.add 1
    expect(scope.variant.line_item.quantity).toEqual 1

  it "adds to the existing quantity", ->
    scope.add 1
    scope.add 5
    expect(scope.variant.line_item.quantity).toEqual 6

  it "adds to the max quantity", ->
    scope.addMax 5
    expect(scope.variant.line_item.quantity).toEqual 0
    expect(scope.variant.line_item.max_quantity).toEqual 5

  it "adds to the max quantity to be at least min quantity", ->
    scope.variant.product.group_buy = true
    scope.variant.line_item.max_quantity = 2

    scope.add 3

    expect(scope.variant.line_item.quantity).toEqual 3
    expect(scope.variant.line_item.max_quantity).toEqual 3

  it "decreases the min quantity to not exceed max quantity", ->
    scope.variant.product.group_buy = true
    scope.variant.line_item.quantity = 3
    scope.variant.line_item.max_quantity = 5

    scope.addMax -3

    expect(scope.variant.line_item.quantity).toEqual 2
    expect(scope.variant.line_item.max_quantity).toEqual 2

  it "allows adding when variant is on demand", ->
    expect(scope.canAdd(5000)).toEqual true

  it "denies adding if variant is out of stock", ->
    scope.variant.on_demand = false
    scope.variant.on_hand = 0

    expect(scope.canAdd(1)).toEqual false

  it "denies adding if stock is limitted", ->
    scope.variant.on_demand = false
    scope.variant.on_hand = 5

    expect(scope.canAdd(4)).toEqual true
    expect(scope.canAdd(5)).toEqual true
    expect(scope.canAdd(6)).toEqual false

    scope.add 3
    expect(scope.canAdd(2)).toEqual true
    expect(scope.canAdd(3)).toEqual false

  it "denies declaring max quantity before item is in cart", ->
    expect(scope.canAddMax(1)).toEqual false

  it "allows declaring max quantity when item is in cart", ->
    scope.add 1
    expect(scope.canAddMax(1)).toEqual true

  it "denies adding if stock is limitted", ->
    scope.variant.on_demand = false
    scope.variant.on_hand = 5
    scope.variant.line_item.quantity = 1
    scope.variant.line_item.max_quantity = 1

    expect(scope.canAddMax(3)).toEqual true
    expect(scope.canAddMax(4)).toEqual true
    expect(scope.canAddMax(5)).toEqual false
    expect(scope.canAddMax(6)).toEqual false
