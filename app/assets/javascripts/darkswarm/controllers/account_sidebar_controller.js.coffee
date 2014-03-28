window.AccountSidebarCtrl = Darkswarm.controller "AccountSidebarCtrl", ($scope, $http, $location, SpreeUser, Navigation) ->
  $scope.path = "/account"
  Navigation.paths.push $scope.path

  $scope.active = ->
    $location.path() == $scope.path

  $scope.select = ->
    Navigation.navigate($scope.path)
