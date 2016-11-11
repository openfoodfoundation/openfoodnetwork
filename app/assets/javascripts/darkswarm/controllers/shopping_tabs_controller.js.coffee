Darkswarm.controller "ShoppingTabsCtrl", ($scope, $controller, Navigation, $location) ->
  angular.extend this, $controller('TabsCtrl', {$scope: $scope})

  $scope.tabs =
    about: { active: Navigation.isActive('/about') }
    producers: { active: Navigation.isActive('/producers') }
    contact: { active: Navigation.isActive('/contact') }
    groups: { active: Navigation.isActive('/groups') }

  $scope.$on '$locationChangeStart', (event, url) ->
    tab = $location.path().replace(/^\//, '')
    $scope.tabs[tab]?.active = true
