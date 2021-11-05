angular.module('Darkswarm').controller "LoginCtrl", ($scope, $timeout, $location, $http, $window, AuthenticationService, Redirections, Loading) ->
  $scope.path = "/login"

  $scope.modalMessage = null

  $scope.$watch (->
    AuthenticationService.modalMessage
  ), (newValue) ->
    $scope.errors = newValue

  $scope.submit = ->
    Loading.message = t 'logging_in'
    $http.post("/user/spree_user/sign_in", {spree_user: $scope.spree_user}).then (response)->
      if window._paq
        window._paq.push(['trackEvent', 'Signin/Signup', 'Login Submit Success', $location.absUrl()]);
      if Redirections.after_login
        $window.location.href = $window.location.origin + Redirections.after_login
      else
        $window.location.href = $window.location.origin + $window.location.pathname  # Strips out hash fragments
    .catch (response) ->
      Loading.clear()
      $scope.errors = response.data.message || response.data.error
      $scope.user_unconfirmed = (response.data.error == t('devise.failure.unconfirmed'))

  $scope.resend_confirmation = ->
    $http.post("/user/spree_user/confirmation", {spree_user: $scope.spree_user, return_url: $location.absUrl()}).then (response)->
      $scope.messages = t('devise.confirmations.send_instructions')
    .catch (response) ->
      $scope.errors = t('devise.confirmations.failed_to_send')

  $timeout ->
    if angular.isDefined($location.search()['validation'])
      if $location.search()['validation'] == 'confirmed'
        $scope.messages = t('devise.confirmations.confirmed')
      if $location.search()['validation'] == 'not_confirmed'
        $scope.errors = t('devise.confirmations.not_confirmed')
