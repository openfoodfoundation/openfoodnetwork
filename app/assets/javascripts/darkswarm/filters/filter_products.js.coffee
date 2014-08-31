Darkswarm.filter 'products', (Matcher)-> 
  (products, text)->
    products ||= []
    text ?= ""
    products.filter (product)=>
      propertiesToMatch = [product.name, product.supplier.name, product.primary_taxon.name]
      Matcher.match propertiesToMatch, text
