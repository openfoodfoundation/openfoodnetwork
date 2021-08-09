angular.module('Darkswarm').directive "focusSearch", ->
  restrict: 'A'
  link: (scope, element, attr)->
    element.bind 'click', (event) ->
      # Focus seach field, ready for typing
      $(element).siblings('#search').focus()
