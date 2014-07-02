Darkswarm.filter 'taxons', (Matcher)-> 
  # Filter anything that responds to object.taxons, and/or object.primary_taxon
  (objects, id) ->
    objects ||= []
    id ?= 0
    objects.filter (obj)->
      obj.primary_taxon?.id == id || obj.taxons.some (taxon)->
        taxon.id == id
