angular.module('Darkswarm').factory 'Shopfront', (shopfront) ->
  new class Shopfront
    shopfront: shopfront
    producers_by_id: {}

    constructor: ->
      for producer in shopfront.producers
        @producers_by_id[producer.id] = producer
