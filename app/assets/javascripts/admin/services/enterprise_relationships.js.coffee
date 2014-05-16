Admin.factory 'EnterpriseRelationships', ($http, enterprise_relationships) ->
  new class EnterpriseRelationships
    constructor: ->
      @enterprise_relationships = enterprise_relationships

    delete: (er) ->
      ers = @enterprise_relationships
      $http.delete('/admin/enterprise_relationships/' + er.id).success (data) ->
        ers.splice ers.indexOf(er), 1
