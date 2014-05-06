Darkswarm.controller "LoginCtrl", ($scope, $http, $location, AuthenticationService) ->
  $scope.path = "/login"

  $scope.submit = ->
    $http.post("/user/spree_user/sign_in", {spree_user: $scope.spree_user}).success (data)->
      location.href = location.origin + location.pathname  # Strips out hash fragments
    .error (data) ->
      $scope.errors = data.message
