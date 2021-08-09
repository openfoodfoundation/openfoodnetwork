angular.module('Darkswarm').directive "mailto", (Navigation)->
  restrict: 'A'
  link: (scope, element, attrs)->
    element.bind 'click', (e)->
      e.preventDefault()
      window.location.href = "mailto:#{attrs.href.split("").reverse().join("")}"
