angular.module("admin.tagRules").directive "invertNumber", ->
  restrict: "A"
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$parsers.push (viewValue) ->
      return -parseInt(viewValue) unless isNaN(parseInt(viewValue))
      viewValue

    ngModel.$formatters.push (modelValue) ->
      return -parseInt(modelValue) unless isNaN(parseInt(modelValue))
      modelValue
