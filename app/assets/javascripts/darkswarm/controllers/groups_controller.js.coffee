Darkswarm.controller "GroupsCtrl", ($scope, Groups, $anchorScroll, $rootScope) ->
  $scope.Groups = Groups
  $scope.order = 'position'

  $rootScope.$on "$locationChangeSuccess", (newRoute, oldRoute) ->
    $anchorScroll()
