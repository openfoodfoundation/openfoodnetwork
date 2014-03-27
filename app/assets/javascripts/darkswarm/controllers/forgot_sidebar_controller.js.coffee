window.ForgotSidebarCtrl = Darkswarm.controller "ForgotSidebarCtrl", ($scope, $http, $location) ->
  $scope.active = ->
    $location.path() == '/forgot'

  $scope.select = ->
    $location.path("/forgot")
