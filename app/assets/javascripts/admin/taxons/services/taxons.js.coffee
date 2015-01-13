angular.module("admin.taxons").factory "Taxons", (taxons, $filter) ->
  new class Taxons
    taxons: taxons
    taxonsByID: {}

    constructor: ->
      for taxon in @taxons
        @taxonsByID[taxon.id] = taxon

    # For finding a single Taxon
    findByID: (id) ->
      @taxonsByID[id]

    # For finding multiple Taxons represented by comma delimited string
    findByIDs: (ids) ->
      @taxonsByID[taxon_id] for taxon_id in ids.split(",") when @taxonsByID[taxon_id]

    findByTerm: (term) ->
      $filter('filter')(@taxons, term)
