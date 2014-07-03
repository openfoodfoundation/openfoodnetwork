Darkswarm.controller "ProducersTabCtrl", ($scope, CurrentHub, Enterprises) ->
  # Injecting Enterprises so CurrentHub.producers is dereferenced
  $scope.CurrentHub = CurrentHub
