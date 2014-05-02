Darkswarm.controller "AuthenticationActionsCtrl", ($scope, Navigation, storage, Sidebar) ->
  $scope.Sidebar = Sidebar

  $scope.toggle = (path)->
    Navigation.navigate(path)
