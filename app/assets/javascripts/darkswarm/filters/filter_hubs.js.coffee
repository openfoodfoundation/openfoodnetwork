Darkswarm.filter 'hubs', (Matcher)-> 
  (hubs, text) ->
    hubs ||= []
    text ?= ""

    hubs.filter (hub)=>
      Matcher.match [
        hub.name, hub.address.zipcode, hub.address.city, hub.address.state
      ], text
