angular.module("admin.utils").filter "translate", ->
  (key, options) ->
    t(key, options)

angular.module("admin.utils").filter "t", ->
  (key, options) ->
    t(key, options)
