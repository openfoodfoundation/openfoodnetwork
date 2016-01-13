angular.module('ofn.admin').filter "translate", ->
  (key, options) ->
    t(key, options)

angular.module('ofn.admin').filter "t", ->
  (key, options) ->
    t(key, options)

