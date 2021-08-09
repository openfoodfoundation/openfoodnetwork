angular.module('Darkswarm').filter 'searchEnterprises', (Matcher)->
  # Search multiple fields of enterprises for matching text fragment.
  (enterprises, text) ->
    enterprises ||= []
    text ?= ""

    enterprises.filter (enterprise)=>
      Matcher.match [
        enterprise.name, enterprise.address.zipcode, enterprise.address.city, enterprise.address.state
      ], text
