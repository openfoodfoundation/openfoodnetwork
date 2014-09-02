Darkswarm.controller "LoginCtrl", ($scope, $http, $window, AuthenticationService, Redirections, Loading) ->
  $scope.path = "/login"

  $scope.submit = ->
    Loading.message = "Hold on a moment, we're logging you in"
    $http.post("/user/spree_user/sign_in", {spree_user: $scope.spree_user}).success (data)->
      if Redirections.after_login
        $window.location.href = $window.location.origin + Redirections.after_login
      else
        $window.location.href = $window.location.origin + $window.location.pathname  # Strips out hash fragments
    .error (data) ->
      Loading.clear()
      $scope.errors = data.message
