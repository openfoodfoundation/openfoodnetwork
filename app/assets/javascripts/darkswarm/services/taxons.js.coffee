Darkswarm.factory "Taxons", (taxons)->
  new class Taxons
    taxons: taxons
    taxons_by_id: {}
    constructor: ->
      # Map taxons to id/object pairs for lookup.
      for taxon in @taxons
        @taxons_by_id[taxon.id] = taxon

