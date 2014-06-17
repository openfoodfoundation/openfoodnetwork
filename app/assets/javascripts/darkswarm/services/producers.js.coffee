Darkswarm.factory 'Producers', (producers) ->
  new class Producers
    constructor: ->
      @producers = producers
      
      # TODO: start adding functionality to producers like so
      #@producers = (@extend(producer) for producer in producers)

    #extend: (producer)->
      #new class Producer
        #constructor: ->
          #@[k] = v for k, v of Producer
