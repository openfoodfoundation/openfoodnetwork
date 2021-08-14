angular.module('Darkswarm').controller "SignupCtrl", ($scope, $http, $window, $location, Redirections, AuthenticationService) ->
  $scope.path = "/signup"

  $scope.spree_user.password_confirmation = ''

  $scope.errors =
    email: null
    password: null

  $scope.submit = ->
    $http.post("/user/spree_user", {spree_user: $scope.spree_user, return_url: $location.absUrl()}).then (response)->
      $scope.errors = {email: null, password: null}
      $scope.messages = t('devise.user_registrations.spree_user.signed_up_but_unconfirmed')
    .catch (response) ->
      $scope.errors = response.data
