Darkswarm.controller "AccordionCtrl", ($scope, storage) ->
  $scope.accordion = 
    details: true 
    shipping: false
    payment: false
    billing: false
  storage.bind $scope, "accordion", {storeName: "accordion_#{$scope.order.id}"}

  $scope.show = (name)->
    $scope.accordion[name] = true

