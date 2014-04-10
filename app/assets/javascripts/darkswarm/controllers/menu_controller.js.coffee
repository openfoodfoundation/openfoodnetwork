window.MenuCtrl = Darkswarm.controller "MenuCtrl", ($scope, Navigation) ->

  $scope.toggleLogin = ->
    Navigation.navigate "/login"

  $scope.toggleSignup = ->
    Navigation.navigate "/signup"

  $scope.toggleSignup = ->
    Navigation.navigate "/signup"

  $scope.toggle = (path = null)->
    Navigation.navigate(path)
