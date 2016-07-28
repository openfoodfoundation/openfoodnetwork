angular.module('admin.orderCycles', ['ui.sortable', 'ngTagsInput', 'admin.indexUtils', 'admin.enterprises'])

  .config ($httpProvider) ->
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')

  .directive 'datetimepicker', ($timeout, $parse) ->
    require: "ngModel"
    link: (scope, element, attrs, ngModel) ->
      $timeout ->
        # using $parse instead of scope[attrs.datetimepicker] for cases
        # where attrs.datetimepicker is 'foo.bar.lol'
        $(element).datetimepicker
        	dateFormat: 'yy-mm-dd'
        	timeFormat: 'HH:mm:ss'
        	showOn: "button"
        	buttonImage: "<%= asset_path 'datepicker/cal.gif' %>"
        	buttonImageOnly: true
        	stepMinute: 15
        	onSelect: (dateText, inst) ->
        	  scope.$apply(->
              element.val(dateText)
        	    parsed = $parse(attrs.datetimepicker)
        	    parsed.assign(scope, dateText)
            )


  .directive 'ofnOnChange', ->
    (scope, element, attrs) ->
      element.bind 'change', ->
        scope.$apply(attrs.ofnOnChange)

  .directive 'ofnSyncDistributions', ->
    (scope, element, attrs) ->
      element.bind 'change', ->
        if !$(this).is(':checked')
          scope.$apply ->
            scope.removeDistributionOfVariant(attrs.ofnSyncDistributions)
