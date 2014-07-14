Darkswarm.factory "Taxons", (taxons)->
  new class Taxons
    taxons: taxons   
    taxons_by_id: {}
    constructor: ->
      for taxon in @taxons
        @taxons_by_id[taxon.id] = taxon

