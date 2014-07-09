Darkswarm.filter 'filterProducers', (hubsFilter)-> 
  (producers, text) ->
    producers ||= []
    text ?= ""
    hubsFilter(producers, text)
    
