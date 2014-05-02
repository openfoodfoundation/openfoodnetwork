Darkswarm.factory 'User', (user)->
  # This is for the current user
  if user and !$.isEmptyObject(user)
    new class User
      constructor: ->
        @[k] = v for k, v of user
  else
    undefined
