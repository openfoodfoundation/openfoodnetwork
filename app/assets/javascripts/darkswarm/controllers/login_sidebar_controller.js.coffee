window.LoginSidebarCtrl = Darkswarm.controller "LoginSidebarCtrl", ($scope, $http, $location, SpreeUser, Navigation) ->
  $scope.spree_user = SpreeUser.spree_user
  $scope.path = "/login"
  Navigation.paths.push $scope.path

  $scope.active = ->
    $location.path() == $scope.path

  $scope.select = ->
    Navigation.navigate($scope.path)


  $scope.submit = ->
    $http.post("/user/spree_user/sign_in", {spree_user: $scope.spree_user}).success (data)->
      location.href = location.origin + location.pathname  # Strips out hash fragments
    .error (data) ->
      $scope.errors = data.message
