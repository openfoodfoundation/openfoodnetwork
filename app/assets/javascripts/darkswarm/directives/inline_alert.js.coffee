angular.module('Darkswarm').directive "ofnInlineAlert", ->
  restrict: 'A'
  scope: true
  link: (scope, elem, attrs) ->
    scope.visible = true
    scope.close = ->
      scope.visible = false
