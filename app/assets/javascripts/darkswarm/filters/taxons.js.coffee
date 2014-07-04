Darkswarm.filter 'taxons', (Matcher)-> 
  # Filter anything that responds to object.taxons, and/or object.primary_taxon
  (objects, ids) ->
    objects ||= []
    ids ?= []
    console.log ids
    if ids.length == 0
      objects
    else
      objects.filter (obj)->
        obj.primary_taxon?.id in ids || obj.taxons.some (taxon)->
          taxon.id in ids
