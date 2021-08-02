angular.module('Darkswarm').controller "GroupTabsCtrl", ($scope, $controller, Navigation) ->
  angular.extend this, $controller('TabsCtrl', {$scope: $scope})

  $scope.tabs =
    map: { active: Navigation.isActive('/map') }
    about: { active: Navigation.isActive('/about') }
    producers: { active: Navigation.isActive('/producers') }
    hubs: { active: Navigation.isActive('/hubs') }
