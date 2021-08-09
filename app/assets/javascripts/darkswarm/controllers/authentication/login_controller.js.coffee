angular.module('Darkswarm').controller "LoginCtrl", ($scope, $timeout, $location, $http, $window, AuthenticationService, Redirections, Loading) ->
  $scope.path = "/login"

  $scope.modalMessage = null

  $scope.$watch (->
    AuthenticationService.modalMessage
  ), (newValue) ->
    $scope.errors = newValue

  $scope.submit = ->
    Loading.message = t 'logging_in'
    $http.post("/user/spree_user/sign_in", {spree_user: $scope.spree_user}).success (data)->
      if Redirections.after_login
        $window.location.href = $window.location.origin + Redirections.after_login
      else
        $window.location.href = $window.location.origin + $window.location.pathname  # Strips out hash fragments
    .error (data) ->
      Loading.clear()
      $scope.errors = data.message || data.error
      $scope.user_unconfirmed = (data.error == t('devise.failure.unconfirmed'))

  $scope.resend_confirmation = ->
    $http.post("/user/spree_user/confirmation", {spree_user: $scope.spree_user, return_url: $location.absUrl()}).success (data)->
      $scope.messages = t('devise.confirmations.send_instructions')
    .error (data) ->
      $scope.errors = t('devise.confirmations.failed_to_send')

  $timeout ->
    if angular.isDefined($location.search()['validation'])
      if $location.search()['validation'] == 'confirmed'
        $scope.messages = t('devise.confirmations.confirmed')
      if $location.search()['validation'] == 'not_confirmed'
        $scope.errors = t('devise.confirmations.not_confirmed')
