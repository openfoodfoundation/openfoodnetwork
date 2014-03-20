window.LoginSidebarCtrl = Darkswarm.controller "LoginSidebarCtrl", ($scope) ->
  $scope.active = ->
    $scope.active_sidebar == '/login'
