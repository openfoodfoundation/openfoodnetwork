Darkswarm.factory 'Producers', (Enterprises) ->
  new class Producers
    constructor: ->
      @producers = Enterprises.enterprises.filter (enterprise)->
        enterprise.enterprise_type == "producer"

