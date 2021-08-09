angular.module('Darkswarm').directive 'cookiesPolicyModal', (CookiesPolicyModalService) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    elem.bind "click", ->
      CookiesPolicyModalService.open ''
