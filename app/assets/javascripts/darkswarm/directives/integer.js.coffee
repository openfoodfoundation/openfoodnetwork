Darkswarm.directive "integer", ->
  restrict: 'A'
  link: (scope, elem, attr) ->
    elem.bind 'input', ->
      digits = elem.val().replace(/\D/g, "")
      elem.val digits
