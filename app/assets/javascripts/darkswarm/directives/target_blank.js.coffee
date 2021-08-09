angular.module('Darkswarm').directive "embeddedTargetBlank", ->
  restrict: 'A'
  compile: (element) ->
    elems = (element.children().find("a"))
    if window.location.search.indexOf("embedded_shopfront=true") != -1
      elems.attr("target", "_blank")