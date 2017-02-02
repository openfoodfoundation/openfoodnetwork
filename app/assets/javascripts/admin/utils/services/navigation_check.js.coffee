angular.module("admin.utils")
  .factory "NavigationCheck", ($window, $rootScope) ->
    new class NavigationCheck
      callbacks = []
      constructor: ->
        if $window.addEventListener
          $window.addEventListener "beforeunload", @onBeforeUnloadHandler
        else
          $window.onbeforeunload = @onBeforeUnloadHandler

        $rootScope.$on "$locationChangeStart", @locationChangeStartHandler

      # Action for regular browser navigation.
      onBeforeUnloadHandler: ($event) =>
        message = @getMessage()
        if message
          # following: https://developer.mozilla.org/en-US/docs/Web/Events/beforeunload
          ($event or $window.event).returnValue = message
          message

      # Action for angular navigation.
      locationChangeStartHandler: ($event) =>
        if not @confirmLeave()
          $event.stopPropagation() if $event.stopPropagation
          $event.preventDefault() if $event.preventDefault
          $event.cancelBubble = true
          $event.returnValue = false

      # Check if leaving is okay
      confirmLeave: =>
        message = @getMessage()
        !message or $window.confirm(message)

      # Runs callback functions to retreive most recently added non-empty message.
      getMessage: ->
        message = null
        message = callback() ? message for callback in callbacks
        message

      register: (callback) =>
        callbacks.push callback

      clear: =>
        if $window.addEventListener
          $window.removeEventListener "beforeunload", @onBeforeUnloadHandler
        else
          $window.onbeforeunload = null

        $rootScope.$on "$locationChangeStart", null

