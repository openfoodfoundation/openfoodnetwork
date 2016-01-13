angular.module("admin.enterprise_groups")
  .controller "sideMenuCtrl", ($scope, SideMenu) ->
    $scope.menu = SideMenu
    $scope.select = SideMenu.select

    $scope.menu.setItems [
      { name: 'Primary Details', icon_class: "icon-user" }
      { name: (t('users')), icon_class: "icon-user" }
      { name: (t('about')), icon_class: "icon-pencil" }
      { name: (t('images')), icon_class: "icon-picture" }
      { name: (t('contact')), icon_class: "icon-phone" }
      { name: (t('web')), icon_class: "icon-globe" }
    ]

    $scope.select(0)
