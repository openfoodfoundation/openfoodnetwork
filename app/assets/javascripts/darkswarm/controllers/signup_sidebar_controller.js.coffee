window.SignupSidebarCtrl = Darkswarm.controller "SignupSidebarCtrl", ($scope) ->
  $scope.spree_user = {}

  $scope.active = ->
    $scope.active_sidebar == '/signup'

  $scope.submit = ->
    $http.post("/user/spree_user", {spree_user: $scope.spree_user}).success (data)->
      location.href = location.origin + location.pathname  # Strips out hash fragments
    .error (data) ->
      $scope.errors = data.message
