Darkswarm.controller "HubsCtrl", ($scope, Hubs, $document, $rootScope, HashNavigation) ->
  $scope.Hubs = Hubs
  $scope.hubs = Hubs.visible

  $rootScope.$on "$locationChangeSuccess", (newRoute, oldRoute) ->
    if HashNavigation.active "hubs"
      $document.scrollTo $("#hubs"), 100, 200
