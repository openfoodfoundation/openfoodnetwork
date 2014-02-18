angular.module("Checkout").controller "SummaryCtrl", ($scope) ->
  $scope.purchase = (event)->
    event.preventDefault()
    console.log "test"
