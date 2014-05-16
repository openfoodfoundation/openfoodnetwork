Admin.controller "AdminEnterpriseRelationshipsCtrl", ($scope, $http, EnterpriseRelationships, Enterprises) ->
  $scope.EnterpriseRelationships = EnterpriseRelationships
  $scope.Enterprises = Enterprises

  $scope.create = ->
    $http.post('/admin/enterprise_relationships', {enterprise_relationship: {parent_id: $scope.parent_id, child_id: $scope.child_id}}).success (data, status) =>
      $scope.EnterpriseRelationships.enterprise_relationships.unshift(data)
      $scope.errors = ""

    .error (response, status) =>
      $scope.errors = response.errors

  $scope.delete = (enterprise_relationship) ->
    if confirm("Are you sure?")
      $scope.EnterpriseRelationships.delete enterprise_relationship
