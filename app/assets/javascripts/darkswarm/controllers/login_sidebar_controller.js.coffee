window.LoginSidebarCtrl = Darkswarm.controller "LoginSidebarCtrl", ($scope, $http, $location) ->
  $scope.spree_user = {
    remember_me: 0
  }

  $scope.active = ->
    $location.path() == '/login'

  $scope.select = ->
    $location.path("/login")

  $scope.submit = ->
    $http.post("/user/spree_user/sign_in", {spree_user: $scope.spree_user}).success (data)->
      location.href = location.origin + location.pathname  # Strips out hash fragments
    .error (data) ->
      $scope.errors = data.message
