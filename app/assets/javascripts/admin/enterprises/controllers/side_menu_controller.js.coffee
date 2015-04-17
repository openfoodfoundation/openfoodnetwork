angular.module("admin.enterprises")
  .controller "sideMenuCtrl", ($scope, $parse, Enterprise, SideMenu, enterprisePermissions) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.menu = SideMenu
    $scope.select = SideMenu.select

    $scope.menu.setItems [
      { name: 'Primary Details', icon_class: "icon-home" }
      { name: 'Users', icon_class: "icon-user" }
      { name: 'Address', icon_class: "icon-map-marker" }
      { name: 'Contact', icon_class: "icon-phone" }
      { name: 'Social', icon_class: "icon-twitter" }
      { name: 'About', icon_class: "icon-pencil" }
      { name: 'Business Details', icon_class: "icon-briefcase" }
      { name: 'Images', icon_class: "icon-picture" }
      { name: "Properties", icon_class: "icon-tags", show: "showProperties()" }
      { name: "Shipping Methods", icon_class: "icon-truck", show: "showShippingMethods()" }
      { name: "Payment Methods", icon_class: "icon-money", show: "showPaymentMethods()" }
      { name: "Enterprise Fees", icon_class: "icon-tasks", show: "showEnterpriseFees()" }
      { name: "Shop Preferences", icon_class: "icon-shopping-cart", show: "showShopPreferences()" }
    ]

    $scope.select(0)


    $scope.showItem = (item) ->
      if item.show?
        $parse(item.show)($scope)
      else
        true

    $scope.showProperties = ->
      !!$scope.Enterprise.is_primary_producer

    $scope.showShippingMethods = ->
      enterprisePermissions.can_manage_shipping_methods && $scope.Enterprise.sells != "none"

    $scope.showPaymentMethods = ->
      enterprisePermissions.can_manage_payment_methods && $scope.Enterprise.sells != "none"

    $scope.showEnterpriseFees = ->
      enterprisePermissions.can_manage_enterprise_fees && ($scope.Enterprise.sells != "none" || $scope.Enterprise.is_primary_producer)

    $scope.showShopPreferences = ->
      $scope.Enterprise.sells != "none"
