angular.module('Darkswarm').directive "obfuscatedEmail", ()->
  restrict: 'C'
  link: (scope, element, attrs)->
    element.on 'cut copy', (event)->
      event.preventDefault()
      clipboardData = event.clipboardData || window.clipboardData || event.originalEvent.clipboardData
      clipboardData.setData('text/plain', document.getSelection().toString().split('').reverse().join(''))
