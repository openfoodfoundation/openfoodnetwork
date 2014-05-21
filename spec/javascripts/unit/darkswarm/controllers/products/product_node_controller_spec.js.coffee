describe "ProductNodeCtrl", ->
  ctrl = null
  scope = null
  product =
    id: 99
    price: 10.00
    variants: []

  beforeEach ->
    module('Darkswarm')
    inject ($controller) ->
      scope =
        product: product
      ctrl = $controller 'ProductNodeCtrl', {$scope: scope}

  describe "determining the price to display for a product", ->
    it "displays the product price when the product does not have variants", ->
      expect(scope.price()).toEqual 10.00

    it "displays the minimum variant price when the product has variants", ->
      scope.product =
        price: 11
        variants: [{price: 22}, {price: 33}]
      expect(scope.price()).toEqual 22
