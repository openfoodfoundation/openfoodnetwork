angular.module("admin.users").directive "ofnUserAutocomplete", ($http) ->
  link: (scope,element,attrs) ->
    setTimeout ->
      element.select2
        multiple: false
        initSelection: (element, callback) ->
          $http.get( Spree.url(Spree.routes.user_search, { ids: element.val() }) ).success (data) ->
            callback(data[0]) if data.length > 0
        ajax:
          url: Spree.routes.user_search
          datatype: 'json'
          data:(term, page) ->
            { q: term }
          results: (data, page) ->
            { results: data }
        formatResult: (user) ->
          user.email
        formatSelection: (user) ->
          user.email