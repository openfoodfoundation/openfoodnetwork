Darkswarm.factory "OfnMap", (Enterprises, EnterpriseListModal, MapConfiguration) ->
  new class OfnMap
    constructor: ->
      @coordinates = {}
      @enterprises = Enterprises.enterprises.filter (enterprise) ->
        # Remove enterprises w/o lat or long
        enterprise.latitude != null || enterprise.longitude != null
      @enterprises = @enterprise_markers(@enterprises)
      self = this

    enterprise_markers: (enterprises) ->
      @extend(enterprise) for enterprise in enterprises

    enterprise_hash: (hash, enterprise) ->
      hash[enterprise.id] = { id: enterprise.id, name: enterprise.name, icon: enterprise.icon_font }
      hash


    # Adding methods to each enterprise
    extend: (enterprise) ->
      marker = @coordinates[[enterprise.latitude, enterprise.longitude]]
      self = this
      if !marker
        marker.icon = MapConfiguration.options.cluster_icon
        self.enterprise_hash(marker.enterprises, enterprise)
        marker.id.push(enterprise.id)
      else
        marker = new class MapMarker
          # We cherry-pick attributes because GMaps tries to crawl
          # our data, and our data is cyclic, so it breaks
          latitude: enterprise.latitude
          longitude: enterprise.longitude
          icon: enterprise.icon
          id: [enterprise.id]
          enterprises: self.enterprise_hash({}, enterprise)
          reveal: =>
            EnterpriseListModal.open this.enterprises
        @coordinates[[enterprise.latitude, enterprise.longitude]] = marker
      marker
