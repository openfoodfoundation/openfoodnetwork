angular.module("admin.indexUtils").directive "select2MinSearch", ($timeout) ->
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    element.select2
      minimumResultsForSearch: attrs.select2MinSearch

    scope.$watch attrs.ngModel, (newVal, oldVal) ->
      $timeout -> element.trigger('change')
