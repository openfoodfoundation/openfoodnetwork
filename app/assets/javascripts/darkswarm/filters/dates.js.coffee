Darkswarm.filter "date_in_words", ->
  (date) ->
    moment(date).fromNow()

Darkswarm.filter "sensible_timeframe", (date_in_wordsFilter)->
  (date) ->
    if moment().add('days', 2) < moment(date)
      t 'orders_open'
    else
      t('closing') + date_in_wordsFilter(date)
