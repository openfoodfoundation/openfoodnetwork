window.ForgotSidebarCtrl = Darkswarm.controller "ForgotSidebarCtrl", ($scope, $http, $location, SpreeUser) ->
  $scope.spree_user = SpreeUser.spree_user
  $scope.sent = false

  $scope.active = ->
    $location.path() == '/forgot'

  $scope.select = ->
    $location.path("/forgot")

  $scope.submit = ->
    if $scope.spree_user.email != null
      $http.post("/user/spree_user/password", {spree_user: $scope.spree_user}).success (data)->
        $scope.sent = true
      .error (data) ->
        $scope.errors = "Email address not found"
    else
      $scope.errors = "You must provide an email address"
