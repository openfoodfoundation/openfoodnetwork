Darkswarm.controller "AccordionCtrl", ($scope, storage, $timeout) ->
  $scope.accordion = 
    details: true 
    shipping: false
    payment: false
    billing: false
  storage.bind $scope, "accordion", {storeName: "accordion_#{$scope.order.id}"}

  $scope.show = (name)->
    $scope.accordion[name] = true

  #$timeout =>
    #if $scope.checkout.$valid
      #for k, v of $scope.accordion
        #$scope.accordion[k] = false
      
