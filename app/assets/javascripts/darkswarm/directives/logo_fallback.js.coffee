Darkswarm.directive "logoFallback", () ->
  restrict: "A"
  link: (scope, elm, attr)->
    console.log elm
    elm.bind('error', ->
      elm.replaceWith("<i class='ofn-i_059-producer'></i>")
    )
