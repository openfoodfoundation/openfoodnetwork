angular.module("admin.users").directive "userSelect", ($sanitize) ->
  scope:
    user: '&userSelect'
    model: '=ngModel'
  link: (scope, element, attrs) ->
    setTimeout ->
      element.select2
        multiple: false
        initSelection: (element, callback) ->
          callback {id: scope.user()?.id, email: scope.user()?.email}
        ajax:
          url: '/admin/search/known_users'
          datatype: 'json'
          data: (term, page) ->
            { q: term }
          results: (data, page) ->
            item.email = $sanitize(item.email) for item in data
            { results: data }
        formatResult: (user) ->
          user.email
        formatSelection: (user) ->
          scope.$apply ->
            scope.model = user if scope.model?
          user.email
