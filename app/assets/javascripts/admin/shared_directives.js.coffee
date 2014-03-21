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

sharedDirectivesModule.directive "ofnSelect2MinSearch", [
  ->
    return (
      link: (scope, element, attrs) ->
        element.select2
          minimumResultsForSearch: attrs.ofnSelect2MinSearch
    )
]

sharedDirectivesModule.directive "ofnToggleColumn", ->
  link: (scope, element, attrs) ->
    element.addClass "unselected"  unless scope.column.visible
    element.click "click", ->
      scope.$apply ->
        if scope.column.visible
          scope.column.visible = false
          element.addClass "unselected"
        else
          scope.column.visible = true
          element.removeClass "unselected"