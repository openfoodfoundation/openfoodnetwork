angular.module('Darkswarm').controller "PaymentCtrl", ($scope, $timeout, savedCreditCards, Dates, $controller) ->
  angular.extend this, $controller('FieldsetMixin', {$scope: $scope})

  $scope.savedCreditCards = savedCreditCards
  $scope.name = "payment"
  $scope.months = Dates.months
  $scope.years = Dates.years

  $scope.secrets.card_month = "1"
  $scope.secrets.card_year = moment().year()

  for card in savedCreditCards when card.is_default
    $scope.secrets.selected_card = card.id
    break

  $scope.summary = ->
    [$scope.Checkout.paymentMethod()?.name]

  $timeout $scope.onTimeout
