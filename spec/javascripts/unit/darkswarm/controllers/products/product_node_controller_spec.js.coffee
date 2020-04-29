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

  describe "#hasVerticalScrollBar", ->
    it "returns false if modal element is not found", ->
      spyOn(angular, 'element').and.returnValue([])

      expect(scope.hasVerticalScrollBar()).toBe false

    it "returns false if scrollHeight is equal to clientHeight", ->
      spyOn(angular, 'element').and.returnValue([{ scrollHeight: 100, clientHeight: 100 }])

      expect(scope.hasVerticalScrollBar()).toBe false

    it "returns false if scrollHeight is smaller than clientHeight", ->
      spyOn(angular, 'element').and.returnValue([{ scrollHeight: 50, clientHeight: 100 }])

      expect(scope.hasVerticalScrollBar()).toBe false

    it "returns true if scrollHeight is bigger than clientHeight", ->
      spyOn(angular, 'element').and.returnValue([{ scrollHeight: 100, clientHeight: 50 }])

      expect(scope.hasVerticalScrollBar()).toBe true
