Darkswarm.factory 'TaxonSelector', (Taxons)->
  new class TaxonSelector
    selectors: []
    constructor: ->
      for taxon in Taxons.taxons
        @selectors.push
          active: false
          taxon: taxon

    active: ->
      @selectors.filter (selector)->
        selector.active
      .map (selector)->
        selector.taxon.id
