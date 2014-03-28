window.SignupSidebarCtrl = Darkswarm.controller "SignupSidebarCtrl", ($scope, $http, $location, SpreeUser) ->
  $scope.spree_user = SpreeUser.spree_user
  $scope.errors =
    email: null
    password: null

  $scope.active = ->
    $location.path() == '/signup'

  $scope.select = ->
    $location.path("/signup")

  $scope.submit = ->
    $http.post("/user/spree_user", {spree_user: $scope.spree_user}).success (data)->
      location.href = location.origin + location.pathname  # Strips out hash fragments
    .error (data) ->
      $scope.errors = data
