angular.module("ofn.admin").directive "select2NoSearch", ($timeout) ->
  restrict: 'CA'
  link: (scope, element, attrs) ->
    $timeout ->
      element.select2
        minimumResultsForSearch: Infinity