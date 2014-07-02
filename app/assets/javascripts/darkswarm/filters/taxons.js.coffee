Darkswarm.filter 'taxons', (Matcher)-> 
  # Filter anything that responds to object.taxons, and/or object.primary_taxon
  (objects, text) ->
    objects ||= []
    text ?= ""
    objects.filter (obj)->
      Matcher.match([obj.primary_taxon?.name || ""], text) || obj.taxons.some (taxon)->
        Matcher.match [taxon.name], text
      

