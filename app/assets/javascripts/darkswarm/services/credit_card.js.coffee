Darkswarm.factory 'CreditCard', ($injector, $rootScope, StripeJS, Navigation, $http, RailsFlashLoader, Loading)->
  new class CreditCard
    errors: {}

    requestToken: (secrets) ->
      #$scope.secrets.name = $scope.secrets.first_name + " " + $scope.secrets.last_name
      secrets.name = @full_name(secrets)
      StripeJS.requestToken(secrets, @submit)

    submit: =>
      $rootScope.$apply ->
        Loading.clear()
      Navigation.go '/account'

    full_name: (secrets) ->
      secrets.first_name + " " + secrets.last_name
