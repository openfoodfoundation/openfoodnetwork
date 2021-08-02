angular.module('Darkswarm').filter 'active', ()->
  (objects, options)->
    objects ||= []
    options ?= null
    
    if options.open and !options.closed
      objects.filter (obj)->
        obj.active
    else if options.closed and !options.open
      objects.filter (obj)->
        !obj.active
    else
      objects

