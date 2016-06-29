angular.module("admin.enterprise_groups")
  .controller "sideMenuCtrl", ($scope, SideMenu) ->
    $scope.menu = SideMenu
    $scope.select = SideMenu.select

    $scope.menu.setItems [
      { name: 'primary_details', label: t('primary_details'), icon_class: "icon-user" }
      { name: 'users', label: t('users'), icon_class: "icon-user" }
      { name: 'about', label: t('about'), icon_class: "icon-pencil" }
      { name: 'images', label: t('images'), icon_class: "icon-picture" }
      { name: 'contact', label: t('admin_entreprise_groups_contact'), icon_class: "icon-phone" }
      { name: 'web', label: t('admin_entreprise_groups_web'), icon_class: "icon-globe" }
    ]

    $scope.select(0)
