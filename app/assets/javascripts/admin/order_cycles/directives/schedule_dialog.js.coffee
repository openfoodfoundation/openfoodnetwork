angular.module("admin.orderCycles").directive 'scheduleDialog', ($window, $compile, $injector, $templateCache, DialogDefaults, Schedules) ->
  restrict: 'A'
  scope:
    scheduleId: '@'
  link: (scope, element, attr) ->
    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      existing = Schedules.byID[scope.scheduleId]
      scope.schedule =
        id: existing?.id
        name: existing?.name || ''
        order_cycle_ids: existing?.order_cycle_ids || []
      scope.submitted = false
      scope.errors = []
      # Compile modal template
      scope.template = $compile($templateCache.get('admin/schedule_dialog.html'))(scope)
      # Set Dialog options
      settings = angular.copy(DialogDefaults)
      scope.template.dialog(angular.extend(settings,{width: $window.innerWidth * 0.6}))
      scope.template.dialog(close: -> scope.template.remove())
      scope.template.dialog('open')

    scope.close = ->
      scope.template.dialog('close')
      return

    scope.submit = ->
      scope.schedule_form.$setPristine()
      scope.submitted = true
      scope.errors = []
      return scope.errors.push("Please select at least one order cycle") unless scope.schedule.order_cycle_ids.length > 0
      if scope.schedule_form.$valid
        method = if scope.schedule.id? then Schedules.update else Schedules.add
        method(scope.schedule).$promise.then (data) ->
          if data.id
            scope.submitted = false
            scope.template.dialog('close')
        , (response) ->
          if response.data.errors
            scope.errors.push(error) for error in response.data.errors
          else
            scope.errors.push("Sorry! Could not create '#{scope.name}'")
      return
