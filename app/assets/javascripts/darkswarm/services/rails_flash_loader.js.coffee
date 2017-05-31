Darkswarm.factory 'RailsFlashLoader', (flash, railsFlash)->
  new class RailsFlashLoader
    # The 'flash' service requires type key to
    # be one of: success, info, warn, error
    typePairings:
      success: 'success'
      error: 'error'
      notice: 'success'
      info: 'info'
      warn: 'warn'

    initFlash: ->
      @loadFlash railsFlash

    loadFlash: (rails_flash)->
      for type, message of rails_flash
        type = @typePairings[type]
        flash[type] = message
