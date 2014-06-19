Darkswarm.factory "MapModal", ($modal, $rootScope)->
  new class MapModal
    open: (enterprise)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise

      scope.enterprise = enterprise
      if enterprise.is_distributor
        scope.hub = enterprise
        $modal.open(templateUrl: "map_modal_hub.html", scope: scope)
      else
        scope.producer = enterprise
        $modal.open(templateUrl: "map_modal_producer.html", scope: scope)
