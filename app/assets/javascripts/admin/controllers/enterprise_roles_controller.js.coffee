angular.module("ofn.admin").controller "AdminEnterpriseRolesCtrl", ($scope, EnterpriseRoles) ->
  $scope.EnterpriseRoles = EnterpriseRoles

  $scope.create = ->
    $scope.EnterpriseRoles.create($scope.user_id, $scope.enterprise_id)

  $scope.delete = (enterprise_role) ->
    if confirm("Are you sure?")
      $scope.EnterpriseRoles.delete enterprise_role
