angular.module('Darkswarm').directive 'auth', (AuthenticationService) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    elem.bind "click", ->
      AuthenticationService.open '/' + attrs.auth

    window.addEventListener "login:modal:open", ->
      AuthenticationService.open '/login'

    scope.$on "$destroy", ->
      window.removeEventListener "login:modal:open"
