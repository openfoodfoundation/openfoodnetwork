Darkswarm.filter 'taxons', (Matcher)-> 
  # Filter anything that responds to object.taxons, and/or object.primary_taxon
  (objects, ids) ->
    objects ||= []
    ids ?= []
    if ids.length == 0
      objects
    else
      objects.filter (obj)->
        obj.primary_taxon?.id in ids || (obj.taxons.concat obj.supplied_taxons).some (taxon)->
          taxon.id in ids
