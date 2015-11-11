angular.module("admin.lineItems").directive "scaleAsCurrency", ($filter) ->
  restrict: "A"
  require: 'ngModel'
  scope:
    factor: "&scaleAsCurrency"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$formatters.push (value) ->
      $filter("currency")(value * scope.factor())
