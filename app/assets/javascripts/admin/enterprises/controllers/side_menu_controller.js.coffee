angular.module("admin.enterprises")
  .controller "sideMenuCtrl", ($scope, $parse, enterprise, SideMenu, enterprisePermissions) ->
    $scope.Enterprise = enterprise
    $scope.menu = SideMenu
    $scope.select = SideMenu.select

    $scope.menu.setItems [
      { name: (t('primary_details')), icon_class: "icon-home" }
      { name: (t('users')), icon_class: "icon-user" }
      { name: (t('address')), icon_class: "icon-map-marker" }
      { name: (t('contact')), icon_class: "icon-phone" }
      { name: (t('social')), icon_class: "icon-twitter" }
      { name: (t('about')), icon_class: "icon-pencil" }
      { name: (t('business_details')), icon_class: "icon-briefcase" }
      { name: (t('images')), icon_class: "icon-picture" }
      { name: (t("properties")), icon_class: "icon-tags", show: "showProperties()" }
      { name: (t("shipping_methods")), icon_class: "icon-truck", show: "showShippingMethods()" }
      { name: (t("payment_methods")), icon_class: "icon-money", show: "showPaymentMethods()" }
      { name: (t("enterprise_fees")), icon_class: "icon-tasks", show: "showEnterpriseFees()" }
      { name: (t("shop_preferences")), icon_class: "icon-shopping-cart", show: "showShopPreferences()" }
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
