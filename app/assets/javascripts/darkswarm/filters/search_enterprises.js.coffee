Darkswarm.filter 'searchEnterprises', (Matcher)->
  (enterprises, text) ->
    enterprises ||= []
    text ?= ""

    enterprises.filter (enterprise)=>
      Matcher.match [
        enterprise.name, enterprise.address.zipcode, enterprise.address.city, enterprise.address.state
      ], text
