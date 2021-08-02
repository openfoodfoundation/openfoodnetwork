angular.module('Darkswarm').filter "translate", ->
  (key, options) ->
    t(key, options)

angular.module('Darkswarm').filter "t", ->
  (key, options) ->
    t(key, options)
