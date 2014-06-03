Darkswarm.controller "PaymentCtrl", ($scope, $timeout) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.name = "payment"

  $scope.months = {1: "January", 2: "February", 3: "March", 4: "April", 5: "May", 6: "June", 7: "July", 8: "August", 9: "September", 10: "October", 11: "November", 12: "December"}
  $scope.years = [moment().year()..(moment().year()+15)]
  $scope.secrets.card_month = "1"
  $scope.secrets.card_year = moment().year()
  $timeout $scope.onTimeout 
