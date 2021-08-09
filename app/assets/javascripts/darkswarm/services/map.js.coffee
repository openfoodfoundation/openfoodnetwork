angular.module('Darkswarm').factory "OfnMap", (Enterprises, EnterpriseListModal, MapConfiguration) ->
  new class OfnMap
    constructor: ->
      @coordinates = {}
      @enterprises = Enterprises.geocodedEnterprises()
      @enterprises = @enterprise_markers(@enterprises)

    enterprise_markers: (enterprises) ->
      @extend(enterprise) for enterprise in enterprises

    enterprise_hash: (hash, enterprise) ->
      hash[enterprise.id] = { id: enterprise.id, name: enterprise.name, icon: enterprise.icon_font }
      hash

    extend_marker: (marker, enterprise) ->
      marker.latitude = enterprise.latitude
      marker.longitude = enterprise.longitude
      marker.icon = enterprise.icon
      marker.id = [enterprise.id]
      marker.enterprises = @enterprise_hash({}, enterprise)

    # Adding methods to each enterprise
    extend: (enterprise) ->
      marker = @coordinates[[enterprise.latitude, enterprise.longitude]]
      if marker
        marker.icon = MapConfiguration.options.cluster_icon
        @enterprise_hash(marker.enterprises, enterprise)
        marker.id.push(enterprise.id)
      else
        marker = new class MapMarker
          # We cherry-pick attributes because GMaps tries to crawl
          # our data, and our data is cyclic, so it breaks
          reveal: =>
            EnterpriseListModal.open this.enterprises
        @extend_marker(marker, enterprise)
        @coordinates[[enterprise.latitude, enterprise.longitude]] = marker
      marker
