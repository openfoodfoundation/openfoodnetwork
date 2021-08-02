angular.module('Darkswarm').filter 'products', (Matcher) ->
  (products, text) ->
    products ||= []
    text ?= ""
    return products if text == ""
    products.filter (product) =>
      propertiesToMatch = [product.name, product.variant_names, product.supplier.name, product.primary_taxon.name, product.meta_keywords]
      Matcher.matchBeginning propertiesToMatch, text
