angular.module("admin.indexUtils").directive "select2MinSearch", ->
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    element.select2
      minimumResultsForSearch: attrs.select2MinSearch

    ngModel.$formatters.push (value) ->
      if (value)
        element.select2('val', value);
