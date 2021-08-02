angular.module('Darkswarm').directive "ofnRegistrationLimitModal", (Navigation, $modal, Loading) ->
  restrict: 'A'
  link: (scope, elem, attr)->
    scope.modalInstance = $modal.open
      templateUrl: 'registration/limit_reached.html'
      windowClass: "login-modal register-modal xlarge"
      backdrop: 'static'

    scope.modalInstance.result.then scope.close, scope.close

    scope.close = ->
      Loading.message = t 'going_back_to_home_page'
      Navigation.go "/"
