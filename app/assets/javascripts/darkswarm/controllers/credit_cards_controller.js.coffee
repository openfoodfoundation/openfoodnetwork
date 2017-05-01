Darkswarm.controller "CreditCardsCtrl", ($scope, $timeout, CreditCard, savedCreditCards, StripeJS, Dates, Loading) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.savedCreditCards = savedCreditCards
  $scope.CreditCard = CreditCard
  $scope.allow_name_change = true
  $scope.disable_fields = false

  $scope.months = Dates.months
  $scope.years = Dates.years

  $scope.secrets = CreditCard.secrets
  $scope.add_card_visible = false

  $scope.storeCard = =>
    CreditCard.requestToken($scope.secrets)

  $scope.toggle = ->
    $scope.add_card_visible = !($scope.add_card_visible)
