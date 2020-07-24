@API_DATETIME_FORMAT = "YYYY-MM-DD HH:mm:SS Z"

Darkswarm.filter "date_in_words", ->
  (date, dateFormat) ->
    dateFormat ?= @API_DATETIME_FORMAT
    moment(date, dateFormat).fromNow()

Darkswarm.filter "sensible_timeframe", (date_in_wordsFilter)->
  (date, dateFormat) ->
    dateFormat ?= @API_DATETIME_FORMAT

    if moment().add(2, 'days') < moment(date, dateFormat)
      t 'orders_open'
    else
      t('closing') + ' ' + date_in_wordsFilter(date)
