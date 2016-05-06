angular.module("admin.customers").factory 'TagsResource', ($resource) ->
  $resource('/admin/tags.json', {}, {
    'index':
      method: 'GET'
      isArray: true
      cache: true
      params:
        enterprise_id: '@enterprise_id'
  })
