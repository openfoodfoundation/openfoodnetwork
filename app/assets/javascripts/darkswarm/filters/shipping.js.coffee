angular.module('Darkswarm').filter 'shipping', ()->
  (objects, options)->
    objects ||= []

    if !options
      objects
    else if options.pickup and !options.delivery
      objects.filter (obj)->
        obj.pickup
    else if options.delivery and !options.pickup
      objects.filter (obj)->
        obj.delivery
    else
      objects
