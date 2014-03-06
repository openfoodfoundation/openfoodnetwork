sharedDirectivesModule = angular.module("ofn.shared_directives", [])

sharedDirectivesModule.directive "datetimepicker", [
  "$parse"
  ($parse) ->
    return (
      require: "ngModel"
      link: (scope, element, attrs, ngModel) ->
        element.datetimepicker
          dateFormat: "yy-mm-dd"
          timeFormat: "HH:mm:ss"
          stepMinute: 15
          onSelect: (dateText, inst) ->
            scope.$apply (scope) ->
              # Fires ngModel.$parsers
              ngModel.$setViewValue dateText
    )
]