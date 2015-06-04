 angular.module("admin.dropdown").directive "ofnCloseOnClick", ($document) ->
   link: (scope, element, attrs) ->
     element.click (event) ->
       event.stopPropagation()
       scope.$emit "offClick"
