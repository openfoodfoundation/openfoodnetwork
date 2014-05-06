Darkswarm.controller "AuthenticationCtrl", ($scope, AuthenticationService, SpreeUser)->
  $scope.open = AuthenticationService.open
  
  $scope.spree_user = SpreeUser.spree_user
  $scope.active = AuthenticationService.active
  $scope.select = AuthenticationService.select
