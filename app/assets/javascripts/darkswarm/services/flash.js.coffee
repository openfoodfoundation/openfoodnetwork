Darkswarm.factory 'Flash', (flash)->
  new class Flash
    loadFlash: (rails_flash)->
      for type, message of rails_flash
        switch type
          when "notice"
            flash.info = message
          else
            flash[type] = message
