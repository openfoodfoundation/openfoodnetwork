angular.module('Darkswarm').controller "ForgotCtrl", ($scope, $http, $location, AuthenticationService) ->
  $scope.path = "/forgot"
  $scope.sent = false

  $scope.submit = ->
    if $scope.spree_user.email != null
      $http.post("/user/spree_user/password", {spree_user: $scope.spree_user}).then (response)->
        $scope.sent = true
      .catch (response) ->
        $scope.errors = response.data.error
        $scope.user_unconfirmed = (response.status == 401)
    else
      $scope.errors = t 'email_required'

  $scope.resend_confirmation = ->
    $http.post("/user/spree_user/confirmation", {spree_user: $scope.spree_user, return_url: $location.absUrl()}).then (response)->
      $scope.messages = t('devise.confirmations.send_instructions')
    .catch (response) ->
      $scope.errors = t('devise.confirmations.failed_to_send')
