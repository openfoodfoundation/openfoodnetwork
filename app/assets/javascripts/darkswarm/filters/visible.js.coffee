angular.module('Darkswarm').filter "visible", ->
  (objects)->
    objects.filter (obj)->
      obj.visible
