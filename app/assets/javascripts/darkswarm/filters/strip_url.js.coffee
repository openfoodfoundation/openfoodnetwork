angular.module('Darkswarm').filter "stripUrl", ->
  stripper = /(https?:\/\/)?(.*)/
  (url) ->
    url.match(stripper).pop()


