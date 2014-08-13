angular.module("ofn.admin").factory 'EnterpriseRoles', ($http, enterprise_roles) ->
  new class EnterpriseRoles
    create_errors: ""

    constructor: ->
      @enterprise_roles = enterprise_roles

    create: (user_id, enterprise_id) ->
      $http.post('/admin/enterprise_roles', {enterprise_role: {user_id: user_id, enterprise_id: enterprise_id}}).success (data, status) =>
        @enterprise_roles.unshift(data)
        @create_errors = ""

      .error (response, status) =>
        @create_errors = response.errors

    delete: (er) ->
      $http.delete('/admin/enterprise_roles/' + er.id).success (data) =>
        @enterprise_roles.splice @enterprise_roles.indexOf(er), 1
