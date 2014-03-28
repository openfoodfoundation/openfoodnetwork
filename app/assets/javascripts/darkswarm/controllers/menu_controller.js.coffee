window.MenuCtrl = Darkswarm.controller "MenuCtrl", ($scope, Navigation) ->

  $scope.toggleLogin = ->
    Navigation.navigate "/login"

  $scope.toggleSignup = ->
    Navigation.navigate "/signup"

  $scope.toggle = ->
    Navigation.navigate()
