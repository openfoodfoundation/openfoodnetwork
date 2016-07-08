angular.module("admin.orderCycles").directive 'scheduleDialog', ($compile, $injector, $templateCache, DialogDefaults, Schedules) ->
  restrict: 'A'
  scope:
    scheduleID: '@'
  link: (scope, element, attr) ->
    scope.submitted = false
    scope.name = ""
    scope.orderCycleIDs = []
    scope.errors = []

    scope.close = ->
      scope.template.dialog('close')
      return

    scope.addSchedule = ->
      scope.schedule_form.$setPristine()
      scope.submitted = true
      scope.errors = []
      if scope.schedule_form.$valid
        Schedules.add({name: scope.name, order_cycle_ids: scope.orderCycleIDs}).$promise.then (data) ->
          if data.id
            scope.name = ""
            scope.orderCycleIDs = ""
            scope.submitted = false
            template.dialog('close')
        , (response) ->
          if response.data.errors
            scope.errors.push(error) for error in response.data.errors
          else
            scope.errors.push("Sorry! Could not create '#{scope.name}'")
      return

    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      # Compile modal template
      scope.template = $compile($templateCache.get('admin/schedule_dialog.html'))(scope)
      # Set Dialog options
      scope.template.dialog(DialogDefaults)
      scope.template.dialog(close: -> scope.template.remove())
      scope.template.dialog('open')
