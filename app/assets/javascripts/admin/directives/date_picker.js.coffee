angular.module("ofn.admin").directive "datepicker", ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    element.datepicker
      dateFormat: "yy-mm-dd"
      onSelect: (dateText, inst) ->
        scope.$apply (scope) ->
          # Fires ngModel.$parsers
          ngModel.$setViewValue dateText