Darkswarm.controller "DetailsCtrl", ($scope) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.name = "details"

  
  #$scope.$watch ->
    #$scope.detailsValid()
  #, (valid)->
    #if valid
      #$scope.show("billing")
  
