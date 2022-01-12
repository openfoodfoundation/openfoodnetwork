angular.module('Darkswarm').filter 'enterpriseMatchesQuery', ->
  (enterprises, matches_query) ->
    enterprises.filter (enterprise) ->
      enterprise.matches_query == matches_query
