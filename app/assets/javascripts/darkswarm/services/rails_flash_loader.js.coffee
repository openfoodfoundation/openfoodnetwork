Darkswarm.factory 'RailsFlashLoader', (flash, railsFlash)->
  new class RailsFlashLoader
    initFlash: ->
      @loadFlash railsFlash
    loadFlash: (rails_flash)->
      for type, message of rails_flash
        flash[type] = message
