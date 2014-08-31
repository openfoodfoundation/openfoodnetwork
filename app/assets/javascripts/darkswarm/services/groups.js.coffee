Darkswarm.factory 'Groups', (groups, Enterprises, Dereferencer) ->
  new class Groups
    groups: groups
    groups_by_id: {} 
    constructor: ->
      for group in @groups
        @groups_by_id[group.id] = group
      @dereference()
    dereference: ->
      for group in @groups
        Dereferencer.dereference group.enterprises, Enterprises.enterprises_by_id 
      for enterprise in Enterprises.enterprises
        Dereferencer.dereference enterprise.groups, @groups_by_id

