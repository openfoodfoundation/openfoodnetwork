angular.module('Darkswarm').filter "byProducer", ->
  (objects, id) ->
    objects ||= []
    id ?= 0
    objects.filter (obj)->
      obj.producer.id == id
