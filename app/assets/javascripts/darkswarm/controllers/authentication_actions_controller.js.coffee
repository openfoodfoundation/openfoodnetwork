window.AuthenticationActionsCtrl = Darkswarm.controller "AuthenticationActionsCtrl", ($scope, Navigation, storage) ->

  $scope.toggleLogin = ->
    Navigation.navigate "/login"

  $scope.toggleSignup = ->
    Navigation.navigate "/signup"

  $scope.toggleSignup = ->
    Navigation.navigate "/signup"

  $scope.toggle = (path = null)->
    Navigation.navigate(path)
