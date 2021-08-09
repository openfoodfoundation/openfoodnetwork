angular.module('Darkswarm').filter 'taxons', ()->
  # Filter anything that responds to object.taxons, object.supplied_taxon or object.primary_taxon.
  (objects, ids) ->
    objects ||= []
    ids ?= []
    if ids.length == 0
      # No taxons selected, pass all objects through.
      objects
    else
      objects.filter (obj)->
        taxons = obj.taxons
        # Combine object taxons with supplied taxons, if they exist.
        taxons = taxons.concat obj.supplied_taxons if obj.supplied_taxons
        # Match primary taxon if it exists, then taxon array.
        obj.primary_taxon?.id in ids || taxons.some (taxon)->
          taxon.id in ids
