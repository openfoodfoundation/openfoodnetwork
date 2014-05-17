Admin.factory "Taxons", ($resource) ->
  resource = $resource "/admin/taxons/search"

  return {
    findByIDs: (ids) ->
      resource.get { ids: ids }

    findByTerm: (term) ->
      resource.get { q: term }

    cleanTaxons: (data) ->
      data['taxons'].map (result) -> result
  }