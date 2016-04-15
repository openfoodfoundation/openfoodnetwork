angular.module("admin.indexUtils").directive "ofnSelect2", ($sanitize, $timeout) ->
  require: 'ngModel'
  restrict: 'C'
  scope:
    data: "="
    minSearch: "@?"
    text: "@?"
    blank: "=?"
  link: (scope, element, attrs, ngModel) ->
    $timeout ->
      scope.text ||= 'name'
      scope.data.unshift(scope.blank) if scope.blank? && typeof scope.blank is "object"

      item.name = $sanitize(item.name) for item in scope.data
      element.select2
        minimumResultsForSearch: scope.minSearch || 0
        data: { results: scope.data, text: scope.text }
        formatSelection: (item) ->
          item[scope.text]
        formatResult: (item) ->
          item[scope.text]

    attrs.$observe 'disabled', (value) ->
      element.select2('enable', !value)

    ngModel.$formatters.push (value) ->
      element.select2('val', value)
      value
