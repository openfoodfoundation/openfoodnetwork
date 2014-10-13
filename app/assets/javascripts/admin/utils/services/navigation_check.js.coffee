angular.module("admin.utils")
  .factory "NavigationCheck", ($window, $rootScope) ->
    callbacks = []

    # Action for regular browser navigation.
    onBeforeUnloadHandler = ($event) ->
      message = getMessage()
      if message
        ($event or $window.event).preventDefault()
        message

    # Action for angular navigation.
    locationChangeStartHandler = ($event) ->
      message = getMessage()
      if message and not $window.confirm(message)
        $event.stopPropagation() if $event.stopPropagation
        $event.preventDefault() if $event.preventDefault
        $event.cancelBubble = true
        $event.returnValue = false

    # Runs callback functions to retreive most recently added non-empty message.
    getMessage = ->
      message = null
      message = callback() ? message for callback in callbacks
      message

    register = (callback) ->
      callbacks.push callback

    if $window.addEventListener
      $window.addEventListener "beforeunload", onBeforeUnloadHandler
    else
      $window.onbeforeunload = onBeforeUnloadHandler

    $rootScope.$on "$locationChangeStart", locationChangeStartHandler

    return register: register
