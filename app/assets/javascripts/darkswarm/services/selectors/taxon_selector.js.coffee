Darkswarm.factory 'TaxonSelector', ->
  new class TaxonSelector
    selectors: []
    # Collect all taxons on the supplied enterprises
    collectTaxons: (enterprises)->
      taxons = {} 
      for enterprise in enterprises
        for taxon in (enterprise.taxons.concat enterprise.supplied_taxons)
          taxons[taxon.id] = taxon
      for id, taxon of taxons
        @selectors.push
          active: false
          taxon: taxon

    active: ->
      @selectors.filter (selector)->
        selector.active
      .map (selector)->
        selector.taxon.id
