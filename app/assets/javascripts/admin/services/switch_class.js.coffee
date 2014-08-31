angular.module("ofn.admin").factory "switchClass", [
  "$timeout"
  ($timeout) ->
    return (element,classToAdd,removeClasses,timeout) ->
      $timeout.cancel element.timeout if element.timeout
      element.removeClass className for className in removeClasses
      element.addClass classToAdd
      intRegex = /^\d+$/
      if timeout && intRegex.test(timeout)
        element.timeout = $timeout(->
          element.removeClass classToAdd
        , timeout, true)
]