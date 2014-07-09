Darkswarm.factory 'TaxonSelector', ->
  new class TaxonSelector
    selectors: []
    selectors_by_id: {}
    # Collect all taxons on the supplied enterprises
    collectTaxons: (enterprises)->
      taxons = {} 
      @selectors = []
      selectors = []
      for enterprise in enterprises
        for taxon in (enterprise.taxons.concat enterprise.supplied_taxons)
          taxons[taxon.id] = taxon
      for id, taxon of taxons
        if @selectors_by_id[id]
          selectors.push @selectors_by_id[id]
        else
          @selectors_by_id[id] = 
            active: false
            taxon: taxon
          selectors.push @selectors_by_id[id]
        @selectors = selectors

    active: ->
      @selectors.filter (selector)->
        selector.active
      .map (selector)->
        selector.taxon.id
