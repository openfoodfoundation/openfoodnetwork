angular.module('Darkswarm').directive "integer", ->
  restrict: 'A'
  link: (scope, elem, attr) ->
    elem.bind 'input', ->
      elem.val Math.round(elem.val())
