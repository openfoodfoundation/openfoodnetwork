angular.module("ofn.admin").controller "AdminEnterpriseRelationshipsCtrl", ($scope, EnterpriseRelationships, Enterprises) ->
  $scope.EnterpriseRelationships = EnterpriseRelationships
  $scope.Enterprises = Enterprises

  $scope.create = ->
    $scope.EnterpriseRelationships.create($scope.parent_id, $scope.child_id)

  $scope.delete = (enterprise_relationship) ->
    if confirm("Are you sure?")
      $scope.EnterpriseRelationships.delete enterprise_relationship
