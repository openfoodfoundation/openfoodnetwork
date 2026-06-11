angular.module('Darkswarm').directive "ofnCarouselSwipe", () ->
  restrict: 'A'
  link: (scope, element, attrs) ->
    startPoint = null
    currentPoint = null
    isSwiping = false
    swipeAxis = null
    startedOnInteractiveElement = false
    swipeThreshold = 40
    swipeActivationThreshold = 10
    horizontalDominanceRatio = 1.5

    isInteractiveElement = (target) ->
      return false unless target?.closest?

      Boolean(target.closest('button, a, input, select, textarea, label'))

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
      startedOnInteractiveElement = isInteractiveElement(event.target)
      return if startedOnInteractiveElement

      point = readPoint(event, 'touches') || readPoint(event)
      return unless point

      startPoint = point
      currentPoint = point
      isSwiping = false
      swipeAxis = null

    onMove = (event) ->
      return if startedOnInteractiveElement

      point = readPoint(event, 'touches') || readPoint(event)
      return unless point && startPoint?

      currentPoint = point
      deltaX = currentPoint.x - startPoint.x
      deltaY = currentPoint.y - startPoint.y
      absDeltaX = Math.abs(deltaX)
      absDeltaY = Math.abs(deltaY)

      return if !swipeAxis && absDeltaX < swipeActivationThreshold && absDeltaY < swipeActivationThreshold

      if !swipeAxis
        if absDeltaX >= swipeActivationThreshold && absDeltaX > (absDeltaY * horizontalDominanceRatio)
          swipeAxis = 'horizontal'
          isSwiping = true
        else if absDeltaY >= swipeActivationThreshold
          swipeAxis = 'vertical'

      if swipeAxis == 'horizontal'
        event.preventDefault?()

    onEnd = (event) ->
      return onCancel() if startedOnInteractiveElement

      point = readPoint(event, 'changedTouches') || readPoint(event) || currentPoint
      return unless point && startPoint?

      deltaX = point.x - startPoint.x
      deltaY = point.y - startPoint.y

      unless isSwiping
        return onCancel()

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
      swipeAxis = null

    onCancel = ->
      startPoint = null
      currentPoint = null
      isSwiping = false
      swipeAxis = null
      startedOnInteractiveElement = false

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