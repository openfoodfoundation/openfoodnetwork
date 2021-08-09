angular.module('Darkswarm').filter "ext_url", ->
  urlPattern = /^https?:\/\//
  (url, prefix) ->
    if !url || url.match(urlPattern)
      url
    else
      prefix + url
