angular.module("ofn.admin").controller "AdminEnterpriseRolesCtrl", ($scope, EnterpriseRoles, Users, Enterprises) ->
  $scope.EnterpriseRoles = EnterpriseRoles
  $scope.Users = Users
  $scope.Enterprises = Enterprises

  $scope.create = ->
    $scope.EnterpriseRoles.create($scope.user_id, $scope.enterprise_id)

  $scope.delete = (enterprise_role) ->
    if confirm(t('are_you_sure'))
      $scope.EnterpriseRoles.delete enterprise_role
