Darkswarm.factory 'SpreeUser', ($resource) ->
  new class SpreeUser
    spree_user: {
      remember_me: 0
      email: null
    }
