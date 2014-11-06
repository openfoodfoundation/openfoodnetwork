Darkswarm.controller "AccordionCtrl", ($scope, storage, $timeout, CurrentHub) ->
  $scope.accordion = 
    details: true 
    shipping: false
    payment: false
    billing: false
  storage.bind $scope, "accordion", {storeName: "accordion_#{$scope.order.id}#{CurrentHub.hub.id}#{$scope.order.user_id}"}

  $scope.show = (section)->
    $scope.accordion[section] = true

  $scope.$on 'purchaseFormInvalid', (event, form) ->
    # Scroll to first invalid section
    # TODO: hide all first
    # TODO: Use Object.keys($scope.accordion)
    sections = ["details", "billing", "shipping", "payment"]
    for section in sections
      if not form[section].$valid
        $scope.show section
        break
