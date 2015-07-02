Darkswarm.filter 'enterpriseMatchesNameQuery', ->
  (enterprises, matches_name_query) ->
    enterprises.filter (enterprise) ->
      enterprise.matches_name_query == matches_name_query
