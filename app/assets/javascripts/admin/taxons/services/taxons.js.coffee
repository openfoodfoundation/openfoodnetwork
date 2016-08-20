angular.module("admin.taxons").factory "Taxons", (taxons, $filter) ->
  new class Taxons
    all: []
    byID: {}

    constructor: ->
      for taxon in taxons
        @all.push taxon
        @byID[taxon.id] = taxon

    # For finding a single Taxon
    findByID: (id) ->
      @byID[id]

    # For finding multiple Taxons represented by comma delimited string
    findByIDs: (ids) ->
      @byID[taxon_id] for taxon_id in ids.split(",") when @byID[taxon_id]

    findByTerm: (term) ->
      $filter('filter')(@all, term)
