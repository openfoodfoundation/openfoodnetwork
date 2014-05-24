angular.module("ofn.admin").directive "ofnSelect2MinSearch", ->
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    element.select2
      minimumResultsForSearch: attrs.ofnSelect2MinSearch

    ngModel.$formatters.push (value) ->
      if (value)
        element.select2('val', value);