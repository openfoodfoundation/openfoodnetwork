Darkswarm.controller "ProducersTabCtrl", ($scope, CurrentHub, Enterprises, EnterpriseModal) ->
  # Injecting Enterprises so CurrentHub.producers is dereferenced.
  # We should probably dereference here instead and separate out CurrentHub dereferencing from the Enterprise factory.
  $scope.CurrentHub = CurrentHub
