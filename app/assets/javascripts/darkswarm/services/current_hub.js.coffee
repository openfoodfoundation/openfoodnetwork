Darkswarm.factory 'CurrentHub', ($location, $filter, currentHub, Enterprises) ->
  Enterprises.enterprises_by_id[currentHub.id] || {}
