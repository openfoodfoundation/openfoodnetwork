 angular.module("admin.dropdown").directive "closeOnClick", () ->
   link: (scope, element, attrs) ->
     element.click (event) ->
       event.stopPropagation()
       scope.$emit "offClick"
