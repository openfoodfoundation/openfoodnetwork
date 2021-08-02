angular.module('Darkswarm').filter 'distanceWithinKm', ->
  (enterprises, range) ->
    enterprises ||= []
    enterprises.filter (enterprise) ->
      enterprise.distance / 1000 <= range
