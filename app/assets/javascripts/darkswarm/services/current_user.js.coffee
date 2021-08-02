angular.module('Darkswarm').factory 'CurrentUser', (user)-> # This is for the current user
  new class CurrentUser
    constructor: ->
      @[k] = v for k, v of user if user and !$.isEmptyObject(user)
