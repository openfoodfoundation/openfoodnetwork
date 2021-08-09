angular.module('Darkswarm').controller "TabsCtrl", ($scope, Navigation) ->
  $scope.isActive = Navigation.isActive

  # Select tab by setting the url hash path.
  $scope.select = (path) ->
    Navigation.navigate path
