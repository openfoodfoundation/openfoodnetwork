describe "ProductNodeCtrl", ->
  ctrl = null
  scope = null
  product =
    id: 99
    price: 10.00
    variants: []
    producer: { }

  beforeEach ->
    module('Darkswarm')
    inject ($controller) ->
      scope =
        product: product
      ctrl = $controller 'ProductNodeCtrl', {$scope: scope}

  it "puts a reference to producer in the scope", ->
    expect(scope.enterprise).toBe product.producer
