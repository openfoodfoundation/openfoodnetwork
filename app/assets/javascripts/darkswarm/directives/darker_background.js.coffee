Darkswarm.directive "darkerBackground", ->
  restrict: "A"
  link: (scope, elm, attr)->
    toggleClass = (value) ->
      elm.closest('.page-view').toggleClass("with-darker-background", value)

    toggleClass(true)
