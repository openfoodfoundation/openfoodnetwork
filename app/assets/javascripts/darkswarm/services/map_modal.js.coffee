Darkswarm.factory "MapModal", ($modal, $rootScope)->
  new class MapModal
    open: (enterprise)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise
      scope.enterprise = enterprise
      if enterprise['is_primary_producer?']
        $modal.open(templateUrl: "map_modal_producer.html", scope: scope)
      else
        $modal.open(templateUrl: "map_modal_hub.html", scope: scope)
