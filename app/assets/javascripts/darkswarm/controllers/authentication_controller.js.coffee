Darkswarm.controller "AuthenticationCtrl", ($scope, AuthenticationService, SpreeUser)->
  $scope.open = AuthenticationService.open
  $scope.toggle = AuthenticationService.toggle

  $scope.spree_user = SpreeUser.spree_user
  $scope.isActive = AuthenticationService.isActive
  $scope.select = AuthenticationService.select
