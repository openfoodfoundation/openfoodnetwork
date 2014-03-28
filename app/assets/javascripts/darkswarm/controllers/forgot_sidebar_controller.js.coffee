window.ForgotSidebarCtrl = Darkswarm.controller "ForgotSidebarCtrl", ($scope, $http, $location, SpreeUser, Navigation) ->
  $scope.spree_user = SpreeUser.spree_user
  $scope.path = "/forgot"
  $scope.sent = false
  Navigation.paths.push $scope.path

  $scope.active = ->
    $location.path() == $scope.path

  $scope.select = ->
    Navigation.navigate($scope.path)

  $scope.submit = ->
    if $scope.spree_user.email != null
      $http.post("/user/spree_user/password", {spree_user: $scope.spree_user}).success (data)->
        $scope.sent = true
      .error (data) ->
        $scope.errors = "Email address not found"
    else
      $scope.errors = "You must provide an email address"
