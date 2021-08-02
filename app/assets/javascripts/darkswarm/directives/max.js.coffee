angular.module('Darkswarm').directive "max",  ->
  restrict: 'A'
  link: (scope, elem, attr)->
    elem.bind 'input', ->
      if elem.val() > +attr.max
        elem.val attr.max
