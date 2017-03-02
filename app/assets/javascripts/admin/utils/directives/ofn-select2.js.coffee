angular.module("admin.utils").directive "ofnSelect2", ($sanitize, $timeout, $filter) ->
  require: 'ngModel'
  restrict: 'C'
  scope:
    data: "="
    minSearch: "@"
    text: "@"
    blank: "=?"
    filter: "=?"
    onSelecting: "=?"
    multiple: '@'
  link: (scope, element, attrs, ngModel) ->
    $timeout ->
      scope.text ?= 'name'
      scope.multiple ?= false
      scope.filter ?= -> true
      scope.placeholder ?= t('admin.choose')

      if scope.data.$promise
        scope.data.$promise.then -> init()
      else
        init()

    element.on "select2-opening", scope.onSelecting || angular.noop

    attrs.$observe 'disabled', (value) ->
      element.select2('enable', !value)

    ngModel.$formatters.push (value) ->
      element.select2('val', value)
      value

    ngModel.$parsers.push (value) ->
      return value.split(",") if scope.multiple
      value

    init = ->
      scope.data.unshift(scope.blank) if scope.blank? && typeof scope.blank is "object"

      item.name = $sanitize(item.name) for item in scope.data
      element.select2
        multiple: scope.multiple
        placeholder: scope.placeholder
        minimumResultsForSearch: scope.minSearch || 0
        data: ->
          filtered = $filter('filter')(scope.data,scope.filter)
          { results: filtered, text: scope.text }
        formatSelection: (item) ->
          item[scope.text]
        formatResult: (item) ->
          item[scope.text]
