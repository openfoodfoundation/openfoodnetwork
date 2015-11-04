angular.module("ofn.admin").directive "ofnConfirmModelChange", (ofnConfirmHandler,$timeout) ->
  restrict: "A"
  link: (scope, element, attrs) ->
    handler = ofnConfirmHandler scope, -> scope.fetchOrders()
    scope.$watch attrs.ngModel, (oldValue,newValue) ->
      handler() unless oldValue == undefined || newValue == oldValue