Darkswarm.controller "CreditCardsCtrl", ($scope, $timeout, CreditCard, savedCreditCards, StripeJS, Dates, Loading) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.savedCreditCards = savedCreditCards
  $scope.CreditCard = CreditCard
  $scope.allow_name_change = true
  $scope.disable_fields = false

  $scope.months = Dates.months
  $scope.years = Dates.years

  $scope.secrets = CreditCard.secrets



  $scope.storeCard = =>
    Loading.message = "Saving"
    CreditCard.requestToken($scope.secrets)





    # Need to call Spree::Gateway::StripeConnect#provider.store(creditcard)
    # creditcard should be formatted as for a payment
    # The token then needs to be associated with the Customer (in Stripe) - can be done in Ruby.
