Darkswarm.directive "darkerBackground", ->
  restrict: "A"
  link: (scope, elm, attr)->
    elm.closest('.page-view').toggleClass("with-darker-background", true)
