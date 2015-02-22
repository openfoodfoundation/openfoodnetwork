Darkswarm.filter "ext_url", () ->
  urlPattern = /^https?:\/\//
  (url, prefix) ->
    if (!url)
      return url
    if (url.match(urlPattern))
      return url
    else
      return prefix + url
