angular.module("ofn.admin").directive "ofnSelect2MinSearch", ->
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    element.select2
      minimumResultsForSearch: attrs.ofnSelect2MinSearch

    ngModel.$formatters.push (value) ->
      # select2 populates options with a value like "number:3" or "string:category" but
      # select2('val', value) doesn't do the type conversion for us as one would expect
      if isNaN(value)
        element.select2('val', "string:#{value}")
      else
        element.select2('val', "number:#{value}")

