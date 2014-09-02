angular.module("ofn.admin").factory 'Users', (users) ->
  new class Users
    constructor: ->
      @users = users
