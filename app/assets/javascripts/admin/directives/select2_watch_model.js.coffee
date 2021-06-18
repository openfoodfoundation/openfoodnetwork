angular.module("ofn.admin").directive "select2WatchNgModel", () ->
  restrict: 'E'
  scope: true
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$render = () ->
      newValue = ngModel.$viewValue;
      element.children(".select2").select2("val", newValue)
