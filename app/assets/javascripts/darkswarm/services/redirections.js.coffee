Darkswarm.factory "Redirections", ($location)->
  new class Redirections
    after_login: $location.search().after_login
