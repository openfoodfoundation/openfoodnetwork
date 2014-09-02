Darkswarm.controller "PaymentCtrl", ($scope, $timeout) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.name = "payment"

  $scope.months = [
    {key: "January", value: "1"},
    {key: "February", value: "2"},
    {key: "March", value: "3"},
    {key: "April", value: "4"},
    {key: "May", value: "5"},
    {key: "June", value: "6"},
    {key: "July", value: "7"},
    {key: "August", value: "8"},
    {key: "September", value: "9"},
    {key: "October", value: "10"},
    {key: "November", value: "11"},
    {key: "December", value: "12"},
  ]

  $scope.years = [moment().year()..(moment().year()+15)]
  $scope.secrets.card_month = "1"
  $scope.secrets.card_year = moment().year()
  $timeout $scope.onTimeout
