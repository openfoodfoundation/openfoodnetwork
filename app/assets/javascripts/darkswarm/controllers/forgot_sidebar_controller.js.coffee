window.ForgotSidebarCtrl = Darkswarm.controller "ForgotSidebarCtrl", ($scope, $http, $location) ->
  $scope.spree_user = {
    email: null
  }

  $scope.active = ->
    $location.path() == '/forgot'

  $scope.select = ->
    $location.path("/forgot")

  $scope.submit = ->
    if $scope.spree_user.email != null
      $http.post("/user/spree_user/password", {spree_user: $scope.spree_user}).success (data)->

        $location.path("/reset")

      .error (data) ->
        $scope.errors = "Email address not found"
    else
      $scope.errors = "You must provide an email address"
