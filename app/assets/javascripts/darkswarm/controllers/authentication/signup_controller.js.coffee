Darkswarm.controller "SignupCtrl", ($scope, $http, $window, $location, Redirections, AuthenticationService) ->
  $scope.path = "/signup"

  $scope.spree_user.password_confirmation = ''

  $scope.errors =
    email: null
    password: null

  $scope.submit = ->
    $http.post("/user/spree_user", {spree_user: $scope.spree_user}).success (data)->
       $scope.messages = t('devise.user_registrations.spree_user.signed_up_but_unconfirmed')
    .error (data) ->
      $scope.errors = data
