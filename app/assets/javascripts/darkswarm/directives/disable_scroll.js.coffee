Darkswarm.directive "ofnDisableScroll", ()->
  restrict: 'A'

  link: (scope, element, attrs)->
    element.bind 'focus', ->
      element.bind 'mousewheel', (e)->
        e.preventDefault()
    element.bind 'blur', ->
      element.unbind 'mousewheel'
