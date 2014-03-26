window.MenuCtrl = Darkswarm.controller "MenuCtrl", ($scope, $location) ->
  $scope.toggleLogin = ->
    if $location.path() == "/login"
      $location.path("/")
    else
      $location.path("login")

  $scope.toggleSignup = ->
    if $location.path() == "/signup"
      $location.path("/")
    else
      $location.path("signup")
