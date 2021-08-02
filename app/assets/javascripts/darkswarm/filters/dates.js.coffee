@API_DATETIME_FORMAT = "YYYY-MM-DD HH:mm:SS Z"

angular.module('Darkswarm').filter "date_in_words", ->
  (date, dateFormat) ->
    dateFormat ?= @API_DATETIME_FORMAT
    moment(date, dateFormat).fromNow()

angular.module('Darkswarm').filter "sensible_timeframe", (date_in_wordsFilter)->
  (date, dateFormat) ->
    dateFormat ?= @API_DATETIME_FORMAT

    if moment().add(2, 'days') < moment(date, dateFormat)
      t 'orders_open'
    else
      t('closing') + ' ' + date_in_wordsFilter(date)
