Darkswarm.controller "DetailsCtrl", ($scope, $timeout) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.name = "details"
  $scope.nextPanel = "billing"

  $scope.summary = ->
    [$scope.fullName(),
    $scope.order.email, 
    $scope.order.bill_address.phone]

  $scope.fullName = ->
    [$scope.order.bill_address.firstname ? null, 
    $scope.order.bill_address.lastname ? null].join(" ").trim()

  $timeout $scope.onTimeout 
