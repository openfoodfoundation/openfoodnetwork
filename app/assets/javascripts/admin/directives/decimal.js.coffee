angular.module("ofn.admin").directive "ofnDecimal", ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    numRegExp = /^\d+(\.\d+)?$/
    element.bind "blur", ->
      scope.$apply ngModel.$setViewValue(ngModel.$modelValue)
      ngModel.$render()

    ngModel.$parsers.push (viewValue) ->
      return viewValue + ".0"  if viewValue.indexOf(".") == -1  if angular.isString(viewValue) and numRegExp.test(viewValue)
      viewValue