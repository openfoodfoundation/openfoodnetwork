Darkswarm.controller "HubsCtrl", ($scope, Hubs, $anchorScroll, $rootScope, HashNavigation) ->
  $scope.Hubs = Hubs
  $scope.hubs = Hubs.hubs

  $rootScope.$on "$locationChangeSuccess", (newRoute, oldRoute) ->
    if HashNavigation.active "hubs"
      $anchorScroll()
