angular.module('Darkswarm').directive "bodyScroll", ($rootScope, BodyScroll) ->
  restrict: 'A'
  scope: true
  link: (scope, elem, attrs) ->
    $rootScope.$on "toggleBodyScroll", ->
      if BodyScroll.disabled && document.body.scrollHeight > document.body.clientHeight
        document.body.style.top = "-#{window.scrollY}px"
        document.body.style.position = 'fixed'
        document.body.style.overflowY = 'scroll'
        document.body.style.width = '100%'
      else
        scrollY = parseInt(document.body.style.top) * -1
        document.body.style.position = ''
        document.body.style.top = ''
        document.body.style.overflowY = ''
        document.body.style.width = ''
        window.scrollTo(0, scrollY) if scrollY
