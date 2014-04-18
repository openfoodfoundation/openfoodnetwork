Darkswarm.directive "ngDebounce", ($timeout) ->
  restrict: "A"
  require: "ngModel"
  priority: 99
  link: (scope, elm, attr, ngModelCtrl) ->
    return  if attr.type is "radio" or attr.type is "checkbox"
    elm.unbind "input"
    debounce = undefined
    elm.bind "keyup paste", ->
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

