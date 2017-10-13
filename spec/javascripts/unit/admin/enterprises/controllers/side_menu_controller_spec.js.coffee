describe "menuCtrl", ->
  ctrl = null
  scope = null
  enterprise = null
  SideMenu = SideMenu

  beforeEach ->
    module('admin.enterprises')
    enterprise =
      payment_method_ids: [ 1, 3 ]
      shipping_method_ids: [ 2, 4 ]
    # PaymentMethods =
    #   paymentMethods: [ { id: 1 }, { id: 2 }, { id: 3 }, { id: 4 } ]
    # ShippingMethods =
    #   shippingMethods: [ { id: 1 }, { id: 2 }, { id: 3 }, { id: 4 } ]

    inject ($rootScope, $controller, _SideMenu_) ->
      scope = $rootScope
      SideMenu = _SideMenu_
      spyOn(SideMenu, "init").and.callThrough()
      spyOn(SideMenu, "select").and.callThrough()
      spyOn(SideMenu, "setItems").and.callThrough()
      ctrl = $controller 'sideMenuCtrl', {$scope: scope, enterprise: enterprise, SideMenu: SideMenu, enterprisePermissions: {}}

  describe "initialisation", ->
    it "stores enterprise", ->
      expect(scope.Enterprise).toEqual enterprise

    it "sets the item list", ->
      expect(SideMenu.setItems).toHaveBeenCalled
      expect(scope.menu.items).toBe SideMenu.items

    it "sets the initally selected value", ->
      expect(SideMenu.init).toHaveBeenCalled()


  describe "selecting an item", ->
    it "selects an item by performing setting the selected property on the item to true", ->
      scope.select 4
      expect(SideMenu.select).toHaveBeenCalledWith 4
      expect(scope.menu.items[4].selected).toBe true
