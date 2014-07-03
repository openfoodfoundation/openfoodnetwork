Darkswarm.factory 'Enterprises', (enterprises, CurrentHub, Dereferencer)->
  new class Enterprises
    enterprises_by_id: {} # id/object pairs for lookup 
    constructor: ->
      @enterprises = enterprises
      for enterprise in enterprises
        @enterprises_by_id[enterprise.id] = enterprise
      @dereference()
    
    dereference: ->
      if CurrentHub.hub?.id
        CurrentHub.hub = @enterprises_by_id[CurrentHub.hub.id]
      for enterprise in @enterprises
        Dereferencer.dereference enterprise.hubs, @enterprises_by_id
        Dereferencer.dereference enterprise.producers, @enterprises_by_id
