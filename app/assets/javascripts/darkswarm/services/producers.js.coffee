Darkswarm.factory 'Producers', (Enterprises, visibleFilter) ->
  new class Producers
    constructor: ->
      @producers = Enterprises.enterprises.filter (enterprise)->
        enterprise.is_primary_producer
      @visible = visibleFilter @producers

