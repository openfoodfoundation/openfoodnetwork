angular.module("admin.enterprises").controller 'NewEnterpriseController', ($scope, defaultCountryID) ->
  $scope.Enterprise =
    address:
      country_id: defaultCountryID
      state_id: null
