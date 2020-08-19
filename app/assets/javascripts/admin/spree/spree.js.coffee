#= require jsuri

class window.Spree
  # Helper function to take a URL and add query parameters to it
  @url: (uri, query) ->
    if uri.path == undefined
      uri = new Uri(uri)
    if query
      $.each query, (key, value) ->
        uri.addQueryParam(key, value)
    if Spree.api_key
      uri.addQueryParam('token', Spree.api_key)
    return uri
