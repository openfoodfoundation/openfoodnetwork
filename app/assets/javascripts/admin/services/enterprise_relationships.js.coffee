angular.module("ofn.admin").factory 'EnterpriseRelationships', ($http, enterprise_relationships) ->
  new class EnterpriseRelationships
    create_errors: ""
    all_permissions: [
      'add_to_order_cycle'
      'manage_products'
      'edit_profile'
      'create_variant_overrides'
    ]

    constructor: ->
      @enterprise_relationships = enterprise_relationships

    create: (parent_id, child_id, permissions) ->
      permissions = (name for name, enabled of permissions when enabled)
      $http.post('/admin/enterprise_relationships', {enterprise_relationship: {parent_id: parent_id, child_id: child_id, permissions_list: permissions}}).success (data, status) =>
        @enterprise_relationships.unshift(data)
        @create_errors = ""

      .error (response, status) =>
        @create_errors = response.errors

    delete: (er) ->
      $http.delete('/admin/enterprise_relationships/' + er.id).success (data) =>
        @enterprise_relationships.splice @enterprise_relationships.indexOf(er), 1

    permission_presentation: (permission) ->
      switch permission
        when "add_to_order_cycle" then "to add to order cycle"
        when "manage_products" then "to manage products"
        when "edit_profile" then "to edit profile"
        when "create_variant_overrides" then "to override variant details"
