Darkswarm.controller "PaymentCtrl", ($scope, $timeout, savedCreditCards) ->
  angular.extend(this, new FieldsetMixin($scope))
  defaultCard = [ {id: null, formatted: t("new_credit_card")} ]
  $scope.savedCreditCards = defaultCard.concat savedCreditCards if savedCreditCards
  $scope.selected_card = null


  $scope.name = "payment"

  $scope.months = [
    {key: t("january"), value: "1"},
    {key: t("february"), value: "2"},
    {key: t("march"), value: "3"},
    {key: t("april"), value: "4"},
    {key: t("may"), value: "5"},
    {key: t("june"), value: "6"},
    {key: t("july"), value: "7"},
    {key: t("august"), value: "8"},
    {key: t("september"), value: "9"},
    {key: t("october"), value: "10"},
    {key: t("november"), value: "11"},
    {key: t("december"), value: "12"},
  ]

  $scope.years = [moment().year()..(moment().year()+15)]
  $scope.secrets.card_month = "1"
  $scope.secrets.card_year = moment().year()

  $scope.summary = ->
    [$scope.Checkout.paymentMethod()?.name]

  $timeout $scope.onTimeout
