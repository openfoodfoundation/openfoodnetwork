Darkswarm.factory 'CurrentUser', (user)-> # This is for the current user
  if user and !$.isEmptyObject(user)
    new class CurrentUser
      constructor: ->
        @[k] = v for k, v of user
  else
    undefined
