angular.module('Darkswarm').factory "Messages", (Loading, RailsFlashLoader)->
  new class Messages
    loading: (message) ->
      Loading.message = message

    success: (message) ->
      @flash(success: message)

    error: (message) ->
      @flash(error: message)

    flash: (flash) ->
      @clear()
      RailsFlashLoader.loadFlash(flash)

    clear: ->
      Loading.clear()
