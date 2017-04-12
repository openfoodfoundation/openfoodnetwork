Darkswarm.filter "date_in_words", ->
  (date) ->
    moment(date).fromNow()

Darkswarm.filter "sensible_timeframe", (date_in_wordsFilter)->
  (date) ->
    if moment().add('days', 2) < moment(date)
      t 'orders_open'
    else
      t('closing') + date_in_wordsFilter(date)

Darkswarm.filter "changesAllowed", ->
  (date) ->
    return t('say_no') unless date?
    return t('spree.users.open_orders.closed') if date < moment()
    t('spree.users.open_orders.until') + " " + moment(date).calendar()
