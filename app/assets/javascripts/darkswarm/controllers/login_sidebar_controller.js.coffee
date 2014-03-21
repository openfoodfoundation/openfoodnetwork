window.LoginSidebarCtrl = Darkswarm.controller "LoginSidebarCtrl", ($scope, $http) ->
  $scope.spree_user = {
    remember_me: 0
  }

  $scope.active = ->
    $scope.active_sidebar == '/login'

  $scope.submit = ->
    $http.post("/user/spree_user/sign_in", {spree_user: $scope.spree_user}).success (data)->
      location.href = location.origin + location.pathname  # Strips out hash fragments
    .error (data) ->
      $scope.errors = data.message

