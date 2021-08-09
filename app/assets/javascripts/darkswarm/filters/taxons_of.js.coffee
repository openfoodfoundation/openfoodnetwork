angular.module('Darkswarm').filter 'taxonsOf', ->
  (objects)->
    taxons = {}
    for object in objects
      for taxon in object.taxons
        taxons[taxon.id] = taxon
      if object.supplied_taxons
        for taxon in object.supplied_taxons
          taxons[taxon.id] = taxon
    taxons
