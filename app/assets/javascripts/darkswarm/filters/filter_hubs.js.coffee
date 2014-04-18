Darkswarm.filter 'filterHubs', -> 
  (hubs, text) ->
    hubs ||= []
    text ?= ""
    match = (matched)->
      matched.indexOf(text) != -1

    hubs.filter (hub)->
      match(hub.name) or match(hub.address.zipcode) or match(hub.address.city)
