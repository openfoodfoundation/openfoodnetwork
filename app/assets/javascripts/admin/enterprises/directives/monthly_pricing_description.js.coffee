angular.module("admin.enterprises").directive "monthlyPricingDescription", (monthlyBillDescription) ->
  restrict: 'E'
  scope:
    joiner: "@"
  template: "<span ng-bind-html='billDescription'></span>"
  link: (scope, element, attrs) ->
    joiners = { comma: ", ", newline: "<br>" }
    scope.billDescription = monthlyBillDescription.replace("{joiner}", joiners[scope.joiner])
