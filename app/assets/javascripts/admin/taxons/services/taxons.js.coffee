angular.module("admin.taxons").factory "Taxons", (taxons, $filter) ->
  new class Taxons
    constructor: ->
      @taxons = taxons

    # For finding a single Taxon
    findByID: (id) ->
      $filter('filter')(@taxons, {id: id}, true)[0]

    # For finding multiple Taxons represented by comma delimited string
    findByIDs: (ids) ->
      taxon for taxon in @taxons when taxon.id.toString() in ids.split(",")

    findByTerm: (term) ->
      $filter('filter')(@taxons, term)