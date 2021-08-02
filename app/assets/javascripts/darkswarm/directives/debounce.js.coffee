angular.module('Darkswarm').directive "ngDebounce", ($timeout) ->
  # Slows down ng-model updates, only triggering binding ngDebounce milliseconds
  # after the last change. Used to prevent squirrely UI
  restrict: "A"
  require: "ngModel"
  priority: 99
  link: (scope, elm, attr, ngModelCtrl) ->
    return  if attr.type is "radio" or attr.type is "checkbox"
    elm.unbind "input"
    debounce = undefined
    elm.bind "keydown paste", ->
      $timeout.cancel debounce
      debounce = $timeout(->
        scope.$apply ->
          ngModelCtrl.$setViewValue elm.val()
          return
        return
      , attr.ngDebounce or 1000)
      return

    elm.bind "blur", ->
      scope.$apply ->
        ngModelCtrl.$setViewValue elm.val()
        return
      return
    return

