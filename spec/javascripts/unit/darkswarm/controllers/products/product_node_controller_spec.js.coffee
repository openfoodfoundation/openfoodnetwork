describe "ProductNodeCtrl", ->
  ctrl = null
  scope = null
  product =
    id: 99
    price: 10.00
    variants: []
    supplier: {}

  beforeEach ->
    module('Darkswarm')
    inject ($controller) ->
      scope =
        product: product
      ctrl = $controller 'ProductNodeCtrl', {$scope: scope}

  it "puts a reference to supplier in the scope", ->
    expect(scope.enterprise).toBe product.supplier
