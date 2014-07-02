Darkswarm.filter 'shipping', ()-> 
  (objects, options)->
    objects ||= []
    options ?= null
    
    if options.pickup and !options.delivery
      objects.filter (obj)->
        obj.pickup
    else if options.delivery and !options.pickup
      objects.filter (obj)->
        obj.delivery
    else
      objects
