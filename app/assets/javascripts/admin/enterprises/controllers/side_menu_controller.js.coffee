angular.module("admin.enterprises")
  .controller "sideMenuCtrl", ($scope, Enterprise, SideMenu) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.menu = SideMenu
    $scope.select = SideMenu.select

    $scope.menu.setItems [
      { name: 'Primary Details', icon_class: "icon-user" }
      { name: 'Address', icon_class: "icon-map-marker" }
      { name: 'Contact', icon_class: "icon-phone" }
      { name: 'Social', icon_class: "icon-twitter" }
      { name: 'About', icon_class: "icon-pencil" }
      { name: 'Business Details', icon_class: "icon-briefcase" }
      { name: 'Images', icon_class: "icon-picture" }
      { name: "Shipping Methods", icon_class: "icon-truck" }
      { name: "Payment Methods", icon_class: "icon-money" }
      { name: "Enterprise Fees", icon_class: "icon-tasks" }
      { name: "Shop Preferences", icon_class: "icon-shopping-cart" }
    ]

    $scope.select(0)
