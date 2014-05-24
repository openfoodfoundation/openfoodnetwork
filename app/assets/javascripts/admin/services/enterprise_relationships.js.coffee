angular.module("ofn.admin").factory 'EnterpriseRelationships', ($http, enterprise_relationships) ->
  new class EnterpriseRelationships
    create_errors: ""

    constructor: ->
      @enterprise_relationships = enterprise_relationships

    create: (parent_id, child_id) ->
      $http.post('/admin/enterprise_relationships', {enterprise_relationship: {parent_id: parent_id, child_id: child_id}}).success (data, status) =>
        @enterprise_relationships.unshift(data)
        @create_errors = ""

      .error (response, status) =>
        @create_errors = response.errors

    delete: (er) ->
      $http.delete('/admin/enterprise_relationships/' + er.id).success (data) =>
        @enterprise_relationships.splice @enterprise_relationships.indexOf(er), 1
