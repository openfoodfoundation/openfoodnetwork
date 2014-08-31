Darkswarm.controller "AccordionCtrl", ($scope, storage, $timeout, CurrentHub) ->
  $scope.accordion = 
    details: true 
    shipping: false
    payment: false
    billing: false
  storage.bind $scope, "accordion", {storeName: "accordion_#{$scope.order.id}#{CurrentHub.hub.id}#{$scope.order.user_id}"}

  $scope.show = (name)->
    $scope.accordion[name] = true

