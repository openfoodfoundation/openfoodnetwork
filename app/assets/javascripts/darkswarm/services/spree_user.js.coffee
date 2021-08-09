angular.module('Darkswarm').factory 'SpreeUser', () ->
  # This is for storing Login/Signup/Forgot data to send to server
  # This does NOT represent our current user
  new class SpreeUser
    spree_user: 
      remember_me: 0
      email: null
