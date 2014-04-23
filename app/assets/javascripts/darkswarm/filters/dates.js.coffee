Darkswarm.filter "date_in_words", ->
  (date) ->
    moment(date).fromNow()

Darkswarm.filter "sensible_timeframe", (date_in_wordsFilter)->
  (date) ->
    if moment().add('days', 2) < moment(date)
      "Orders open"
    else
      "Closing in #{date_in_wordsFilter(date)}"
