angular.module("admin.enterprises")
  .controller "sideMenuCtrl", ($scope, Enterprise, SideMenu) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.menu = SideMenu
    $scope.select = SideMenu.select

    SideMenu.setItems [
      { name: 'Primary Details' }
      { name: 'Address' }
      { name: "Shipping Methods"}
      { name: "Payment Methods"}
      { name: "Enterprise Fees"}
      { name: 'Contact & Social' }
      { name: 'About' }
      { name: "Business Details"}
      { name: 'Images' }
      { name: "Preferences"}
    ]

    $scope.select(0)
