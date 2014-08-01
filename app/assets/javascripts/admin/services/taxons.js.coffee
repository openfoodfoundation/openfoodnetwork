angular.module("ofn.admin").factory "Taxons", (taxons, $filter) ->
  new class Taxons
    constructor: ->
      @taxons = taxons

    findByIDs: (ids) ->
      taxons = []
      taxons.push taxon for taxon in @taxons when taxon.id.toString() in ids.split(",")
      taxons

    findByTerm: (term) ->
      $filter('filter')(@taxons, term)