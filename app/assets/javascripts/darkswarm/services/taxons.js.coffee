angular.module('Darkswarm').factory "Taxons", (taxons)->
  new class Taxons
    # Populate Taxons.taxons from json in page.
    taxons: taxons
    taxons_by_id: {}
    constructor: ->
      # Map taxons to id/object pairs for lookup.
      for taxon in @taxons
        @taxons_by_id[taxon.id] = taxon

