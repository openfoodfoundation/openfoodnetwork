angular.module('Darkswarm').filter 'closedShops', ->
  (enterprises, show_closed) ->
    enterprises ||= []
    show_closed ?= false

    enterprises.filter (enterprise) =>
      show_closed or enterprise.active or !enterprise.is_distributor
