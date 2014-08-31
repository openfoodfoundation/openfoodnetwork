Darkswarm.directive "fillVertical", ($window)->
  restrict: 'A'

  link: (scope, element, attrs)->
    setSize = ->
      element.css "height", ($window.innerHeight - element.offset().top)
    setSize()

    angular.element($window).bind "resize", ->
      setSize()
