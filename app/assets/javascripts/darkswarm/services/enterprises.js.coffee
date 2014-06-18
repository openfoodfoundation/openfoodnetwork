Darkswarm.factory 'Enterprises', (enterprises)->
  new class Enterprises
    enterprises_by_id: {} # id/object pairs for lookup 
    constructor: ->
      @enterprises = enterprises
      for enterprise in enterprises
        @enterprises_by_id[enterprise.id] = enterprise
