window.SignupSidebarCtrl = Darkswarm.controller "SignupSidebarCtrl", ($scope) ->
  $scope.active = ->
    $scope.active_sidebar == '/signup'
