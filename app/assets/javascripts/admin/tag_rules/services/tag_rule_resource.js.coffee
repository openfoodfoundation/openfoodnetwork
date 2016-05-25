angular.module("admin.tagRules").factory 'TagRuleResource', ($resource) ->
  $resource('/admin/tag_rules/:action.json', {}, {
    'mapByTag':
      method: 'GET'
      isArray: true
      cache: true
      params:
        action: 'map_by_tag'
        enterprise_id: '@enterprise_id'
  })
