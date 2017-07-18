Darkswarm.controller "SignupCtrl", ($scope, $http, $window, $location, Redirections, AuthenticationService) ->
  $scope.path = "/signup"

  $scope.spree_user.password_confirmation = ''

  $scope.errors =
    email: null
    password: null

  $scope.submit = ->
    $http.post("/user/spree_user", {spree_user: $scope.spree_user}).success (data)->
       if Redirections.after_login
        $window.location.href = $window.location.origin + Redirections.after_login
       else
        $window.location.href = $window.location.origin + $window.location.pathname  # Strips out hash fragments
    .error (data) ->
      $scope.errors = data
