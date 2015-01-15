angular.module("admin.enterprise_groups")
  .controller "sideMenuCtrl", ($scope, SideMenu) ->
    $scope.menu = SideMenu
    $scope.select = SideMenu.select

    $scope.menu.setItems [
      { name: 'Primary Details', icon_class: "icon-user" }
      { name: 'About', icon_class: "icon-pencil" }
      { name: 'Images', icon_class: "icon-picture" }
      { name: 'Contact', icon_class: "icon-phone" }
    ]

    $scope.select(0)
