Darkswarm.controller "ForgotCtrl", ($scope, $http, $location, AuthenticationService) ->
  $scope.path = "/forgot"
  $scope.sent = false

  $scope.submit = ->
    if $scope.spree_user.email != null
      $http.post("/user/spree_user/password", {spree_user: $scope.spree_user}).success (data)->
        $scope.sent = true
      .error (data) ->
        $scope.errors = t 'email_not_found'
    else
      $scope.errors = t 'email_required'
