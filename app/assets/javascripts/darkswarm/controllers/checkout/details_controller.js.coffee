Darkswarm.controller "DetailsCtrl", ($scope) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.name = "details"


  #$scope.detailsValid = ->
    #$scope.detailsFields().every (field)->
      #$scope.checkout[field].$valid
  
  #$scope.$watch ->
    #$scope.detailsValid()
  #, (valid)->
    #if valid
      #$scope.show("billing")
  
