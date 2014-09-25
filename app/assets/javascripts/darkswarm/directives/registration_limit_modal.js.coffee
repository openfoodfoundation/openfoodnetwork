Darkswarm.directive "ofnRegistrationLimitModal", (Navigation, $modal, Loading) ->
  restrict: 'A'
  link: (scope, elem, attr)->
    scope.modalInstance = $modal.open
      templateUrl: 'registration/limit_reached.html'
      windowClass: "login-modal large"
      backdrop: 'static'

    scope.modalInstance.result.then scope.close, scope.close

    scope.close = ->
      Loading.message = "Taking you back to the home page"
      Navigation.go "/"
