Darkswarm.directive 'auth', (AuthenticationService) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    elem.bind "click", ->
      AuthenticationService.open '/' + attrs.auth
