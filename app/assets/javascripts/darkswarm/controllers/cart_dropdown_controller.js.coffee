Darkswarm.controller "CartDropdownCtrl", ($scope) ->
  $scope.showCartSidebar = false

  $scope.toggleCartSidebar = ->
    $scope.showCartSidebar = !$scope.showCartSidebar
