window.MenuCtrl = Darkswarm.controller "MenuCtrl", ($scope, $location) ->
  $scope.toggleLogin = ->
    if $location.path() == "/login"
      $location.url("/")
    else
      $location.url("login#sidebar")

  $scope.toggleSignup = ->
    if $location.path() == "/signup"
      $location.url("/")
    else
      $location.url("signup#sidebar")
