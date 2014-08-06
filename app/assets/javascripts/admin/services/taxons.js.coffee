angular.module("ofn.admin").factory "Taxons", (taxons, $filter) ->
  new class Taxons
    constructor: ->
      @taxons = taxons

    findByIDs: (ids) ->
      taxon for taxon in @taxons when taxon.id in ids.split(",")

    findByTerm: (term) ->
      $filter('filter')(@taxons, term)