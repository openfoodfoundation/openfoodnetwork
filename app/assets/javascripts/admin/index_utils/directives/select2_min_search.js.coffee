angular.module("admin.indexUtils").directive "select2MinSearch", ($timeout) ->
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    element.select2
      minimumResultsForSearch: attrs.select2MinSearch

    ngModel.$formatters.push (value) ->
      element.select2('val', value)
      value
