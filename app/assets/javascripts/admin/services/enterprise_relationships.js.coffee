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
      $http.post('/admin/enterprise_relationships', {enterprise_relationship: {parent_id: parent_id, child_id: child_id, permissions_list: permissions}}).then (response) =>
        @enterprise_relationships.unshift(response.data)
        @create_errors = ""

      .catch (response) =>
        @create_errors = response.data.errors

    delete: (er) ->
      $http.delete('/admin/enterprise_relationships/' + er.id).then (response) =>
        @enterprise_relationships.splice @enterprise_relationships.indexOf(er), 1

    permission_presentation: (permission) ->
      switch permission
        when "add_to_order_cycle" then t('js.services.add_to_order_cycle')
        when "manage_products" then t('js.services.manage_products')
        when "edit_profile" then t('js.services.edit_profile')
        when "create_variant_overrides" then t('js.services.add_products_to_inventory')
