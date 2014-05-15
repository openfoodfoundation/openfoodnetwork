Darkswarm.controller "DetailsCtrl", ($scope) ->
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

  
  #$scope.$watch ->
    #$scope.detailsValid()
  #, (valid)->
    #if valid
      #$scope.show("billing")
  
