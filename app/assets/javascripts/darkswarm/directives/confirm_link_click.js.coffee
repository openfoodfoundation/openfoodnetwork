Darkswarm.directive "confirmLinkClick", ($window) ->
  restrict: 'A'
  scope:
    confirmMsg: '@confirmLinkClick'
  link: (scope, elem, attr) ->
    elem.bind 'click', (event) ->
      unless confirm(scope.confirmMsg)
        event.preventDefault()
        event.stopPropagation()
