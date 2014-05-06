Darkswarm.controller "SignupCtrl", ($scope, $http, $location, AuthenticationService) ->
  $scope.path = "/signup"
  $scope.errors =
    email: null
    password: null

  $scope.submit = ->
    $http.post("/user/spree_user", {spree_user: $scope.spree_user}).success (data)->
      location.href = location.origin + location.pathname  # Strips out hash fragments
    .error (data) ->
      $scope.errors = data
