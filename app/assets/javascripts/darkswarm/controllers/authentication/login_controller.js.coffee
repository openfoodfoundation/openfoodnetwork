Darkswarm.controller "LoginCtrl", ($scope, $http, AuthenticationService, Redirections, Loading) ->
  $scope.path = "/login"

  $scope.submit = ->
    Loading.message = "Hold on a moment, we're logging you in"
    $http.post("/user/spree_user/sign_in", {spree_user: $scope.spree_user}).success (data)->
      if Redirections.after_login
        location.href = location.origin + Redirections.after_login
      else
        location.href = location.origin + location.pathname  # Strips out hash fragments
    .error (data) ->
      Loading.clear()
      $scope.errors = data.message
