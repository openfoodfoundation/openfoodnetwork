Darkswarm.filter "stripUrl", ->
  stripper = /(https?:\/\/)?(www\.)?(.*)/
  (url) ->
    url.match(stripper).pop()


