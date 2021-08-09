angular.module('Darkswarm').directive "logoFallback", () ->
  restrict: "A"
  link: (scope, elm, attr)->
    elm.bind('error', ->
      elm.replaceWith("<i class='ofn-i_059-producer'></i>")
    )
