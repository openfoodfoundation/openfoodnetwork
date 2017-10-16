#https://stackoverflow.com/questions/3548920/google-maps-api-v3-multiple-markers-on-exact-same-spot

MAX_ZOOM_LEVEL = 18

Darkswarm.factory "MapConfiguration", (EnterpriseModal) ->
  new class MapConfiguration
    options:
      doCluster: true
      clusterOptions: {imagePath: 'assets/map_005-cluster', imageExtension: 'png', imageSizes: [36]}
      clusterEvents:
        click: (cluster, clusterModels) ->
          map = cluster.map_

          should_open_modal = (
            map.zoom == MAX_ZOOM_LEVEL
          )

          return unless should_open_modal

          cluster.markerClusterer_.zoomOnClick_ = false
          enterprises = clusterModels.map((model) -> model.getEnterprise())
          EnterpriseModal.open enterprises
      center:
        latitude: -37.916246
        longitude: 145.343687
      zoom: 12
      additional_options:
        # mapTypeId: 'satellite'
        mapTypeId: 'OSM'
        mapTypeControl: false
        streetViewControl: false
      styles: [{"featureType":"landscape","stylers":[{"saturation":-100},{"lightness":65},{"visibility":"on"}]},{"featureType":"poi","stylers":[{"saturation":-100},{"lightness":51},{"visibility":"simplified"}]},{"featureType":"road.highway","stylers":[{"saturation":-100},{"visibility":"simplified"}]},{"featureType":"road.arterial","stylers":[{"saturation":-100},{"lightness":30},{"visibility":"on"}]},{"featureType":"road.local","stylers":[{"saturation":-100},{"lightness":40},{"visibility":"on"}]},{"featureType":"transit","stylers":[{"saturation":-100},{"visibility":"simplified"}]},{"featureType":"administrative.province","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"labels","stylers":[{"visibility":"on"},{"lightness":-25},{"saturation":-100}]},{"featureType":"water","elementType":"geometry","stylers":[{"hue":"#ffff00"},{"lightness":-25},{"saturation":-97}]},{"featureType":"road","elementType": "labels.icon","stylers":[{"visibility":"off"}]}]

