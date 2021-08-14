angular.module("ofn.admin").factory 'EnterpriseRoles', ($http, enterpriseRoles) ->
  new class EnterpriseRoles
    create_errors: ""

    constructor: ->
      @enterprise_roles = enterpriseRoles

    create: (user_id, enterprise_id) ->
      $http.post('/admin/enterprise_roles', {enterprise_role: {user_id: user_id, enterprise_id: enterprise_id}}).then (response) =>
        @enterprise_roles.unshift(response.data)
        @create_errors = ""

      .catch (response) =>
        @create_errors = response.data.errors

    delete: (er) ->
      $http.delete('/admin/enterprise_roles/' + er.id).then (response) =>
        @enterprise_roles.splice @enterprise_roles.indexOf(er), 1
