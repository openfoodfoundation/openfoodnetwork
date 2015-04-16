Darkswarm.controller "GroupPageCtrl", ($scope, group_enterprises, Enterprises, MapConfiguration, OfnMap) ->
  $scope.Enterprises = Enterprises

  group_enterprises_ids = group_enterprises.map (enterprise) =>
    enterprise.id
  is_in_group = (enterprise) ->
    group_enterprises_ids.indexOf(enterprise.id) != -1

  $scope.group_producers = Enterprises.producers.filter is_in_group
  $scope.group_hubs = Enterprises.hubs.filter is_in_group

  $scope.map = angular.copy MapConfiguration.options
  $scope.mapMarkers = OfnMap.enterprise_markers group_enterprises

