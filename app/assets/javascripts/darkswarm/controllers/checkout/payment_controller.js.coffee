Darkswarm.controller "PaymentCtrl", ($scope, $timeout, savedCreditCards, Dates) ->
  angular.extend(this, new FieldsetMixin($scope))

  $scope.savedCreditCards = savedCreditCards
  $scope.name = "payment"
  $scope.months = Dates.months
  $scope.years = Dates.years

  $scope.secrets.card_month = "1"
  $scope.secrets.card_year = moment().year()

  $scope.summary = ->
    [$scope.Checkout.paymentMethod()?.name]

  $timeout $scope.onTimeout
