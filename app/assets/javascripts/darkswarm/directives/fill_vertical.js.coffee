Darkswarm.directive "fillVertical", ($window)->
  # Makes something fill the window vertically. Used on the Google Map.
  restrict: 'A'
  link: (scope, element, attrs)->
    setSize = ->
      element.css "height", ($window.innerHeight - element.offset().top)
    setSize()
    angular.element($window).bind "resize", ->
      setSize()
