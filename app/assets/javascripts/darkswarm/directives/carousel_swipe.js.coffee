angular.module('Darkswarm').directive "ofnCarouselSwipe", () ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    startPoint = null
    currentPoint = null
    isSwiping = false
    swipeThreshold = 40

    readPoint = (event, key = null) ->
      source = event.originalEvent || event

      if key?
        touches = source[key]
        return null unless touches && touches.length

        return {
          x: touches[0].clientX
          y: touches[0].clientY
        }

      if source.pointerType? && source.pointerType == 'mouse'
        return null

      clientX = source.clientX
      clientY = source.clientY
      return null unless clientX? && clientY?

      {
        x: clientX
        y: clientY
      }

    onStart = (event) ->
      point = readPoint(event, 'touches') || readPoint(event)
      return unless point

      startPoint = point
      currentPoint = point
      isSwiping = false

    onMove = (event) ->
      point = readPoint(event, 'touches') || readPoint(event)
      return unless point && startPoint?

      currentPoint = point
      deltaX = currentPoint.x - startPoint.x
      deltaY = currentPoint.y - startPoint.y

      if Math.abs(deltaX) > Math.abs(deltaY)
        isSwiping = true
        event.preventDefault?()

    onEnd = (event) ->
      point = readPoint(event, 'changedTouches') || readPoint(event) || currentPoint
      return unless point && startPoint?

      deltaX = point.x - startPoint.x
      deltaY = point.y - startPoint.y

      if Math.abs(deltaX) > swipeThreshold && Math.abs(deltaX) > Math.abs(deltaY)
        event.preventDefault?()
        scope.$applyAsync ->
          if deltaX < 0
            scope.$eval(attrs.onSwipeLeft)
          else
            scope.$eval(attrs.onSwipeRight)

      startPoint = null
      currentPoint = null
      isSwiping = false

    onCancel = ->
      startPoint = null
      currentPoint = null
      isSwiping = false

    element.bind 'touchstart', onStart
    element.bind 'touchmove', onMove
    element.bind 'touchend', onEnd
    element.bind 'touchcancel', onCancel
    element.bind 'pointerdown', onStart
    element.bind 'pointermove', onMove
    element.bind 'pointerup', onEnd
    element.bind 'pointercancel', onCancel

    scope.$on '$destroy', ->
      element.unbind 'touchstart', onStart
      element.unbind 'touchmove', onMove
      element.unbind 'touchend', onEnd
      element.unbind 'touchcancel', onCancel
      element.unbind 'pointerdown', onStart
      element.unbind 'pointermove', onMove
      element.unbind 'pointerup', onEnd
      element.unbind 'pointercancel', onCancel