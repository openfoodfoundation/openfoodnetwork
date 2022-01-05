class window.Spree
  # Helper function to take a URL and add query parameters to it
  @url: (uri) ->
    if uri.pathname == undefined
      uri = new URL(uri.toString())
    if Spree.api_key
      params = new URLSearchParams(uri.search)
      params.append('token', Spree.api_key)

    return uri
