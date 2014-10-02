Darkswarm.factory 'Enterprises', (enterprises, CurrentHub, Taxons, Dereferencer, visibleFilter)->
  new class Enterprises
    enterprises_by_id: {} # id/object pairs for lookup
    constructor: ->
      @enterprises = visibleFilter enterprises
      for enterprise in enterprises
        @enterprises_by_id[enterprise.id] = enterprise
      @dereferenceEnterprises()
      @dereferenceTaxons()
      @producers = @enterprises.filter (enterprise)->
        enterprise.is_primary_producer
      @hubs = @enterprises.filter (enterprise)->
        enterprise.is_distributor

    dereferenceEnterprises: ->
      if CurrentHub.hub?.id
        CurrentHub.hub = @enterprises_by_id[CurrentHub.hub.id]
      for enterprise in @enterprises
        Dereferencer.dereference enterprise.hubs, @enterprises_by_id
        Dereferencer.dereference enterprise.producers, @enterprises_by_id

    dereferenceTaxons: ->
      for enterprise in @enterprises
        Dereferencer.dereference enterprise.taxons, Taxons.taxons_by_id
        Dereferencer.dereference enterprise.supplied_taxons, Taxons.taxons_by_id

