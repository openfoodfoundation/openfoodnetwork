window.Shop = angular.module("Shop", ["ngResource", "filters"]).config ($httpProvider) ->
  $httpProvider.defaults.headers.post['X-CSRF-Token'] = $('meta[name="csrf-token"]').attr('content') 


angular.module("filters", []).filter "truncate", ->
  (text, length, end) ->
    text = text || ""
    length = 10  if isNaN(length)
    end = "..."  if end is `undefined`
    if text.length <= length or text.length - end.length <= length
      text
    else
      String(text).substring(0, length - end.length) + end

$.timeago.settings.allowFuture = true;
angular.module("filters").filter "date_in_words", ->
  (date) ->
    $.timeago(date)
