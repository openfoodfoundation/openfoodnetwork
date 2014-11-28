angular.module("admin.enterprises")
  .controller "sideMenuCtrl", ($scope, Enterprise, SideMenu) ->
    $scope.Enterprise = Enterprise.enterprise
    $scope.menu = SideMenu
    $scope.select = SideMenu.select

    $scope.menu.setItems [
      { name: 'Primary Details' }
      { name: 'Address' }
      { name: 'Contact' }
      { name: 'Social' }
      { name: 'About' }
      { name: 'Business Details' }
      { name: 'Images' }
      { name: "Shipping Methods" }
      { name: "Payment Methods" }
      { name: "Enterprise Fees" }
      { name: "Preferences" }
    ]

    $scope.select(0)
