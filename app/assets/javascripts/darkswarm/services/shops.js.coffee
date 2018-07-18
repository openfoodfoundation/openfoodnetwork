angular.module("Darkswarm").factory 'Shops', ($injector) ->
  new class Shops
    all: []
    byID: {}

    constructor: ->
      if $injector.has('shops')
        @load($injector.get('shops'))

    load: (shops) ->
      for shop in shops
        @all.push shop
        @byID[shop.id] = shop
