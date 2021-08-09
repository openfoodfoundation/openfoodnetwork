angular.module('Darkswarm').directive "changeableOrdersAlert", (ChangeableOrdersAlert) ->
  restrict: "C"
  scope: true
  link: (scope, element, attrs) ->
    scope.alert = ChangeableOrdersAlert
