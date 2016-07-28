angular.module("admin.orderCycles").directive 'scheduleDialog', ($window, $compile, $injector, $templateCache, DialogDefaults, OrderCycles, Schedules) ->
  restrict: 'A'
  scope:
    scheduleId: '@'
    showMore: '&'
  link: (scope, element, attr) ->
    # Link opening of dialog to click event on element
    element.bind 'click', (e) ->
      existing = Schedules.byID[scope.scheduleId]
      scope.schedule =
        id: existing?.id
        name: existing?.name || ''
        order_cycle_ids: existing?.order_cycle_ids || []
      scope.selectedOrderCycles = []
      scope.selectedOrderCycles.push orderCycle for orderCycle in (existing?.order_cycles || [])
      scope.availableOrderCycles = (orderCycle for id, orderCycle of OrderCycles.byID when orderCycle.id not in scope.schedule.order_cycle_ids)
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

    scope.loadMore = ->
      scope.showMore().then ->
        scope.availableOrderCycles = (orderCycle for id, orderCycle of OrderCycles.byID when orderCycle.id not in scope.schedule.order_cycle_ids)

    scope.submit = ->
      scope.schedule_form.$setPristine()
      scope.submitted = true
      scope.errors = []
      return scope.errors.push(t('admin.order_cycles.index.no_order_cycles_error')) unless scope.selectedOrderCycles.length > 0
      scope.schedule.order_cycle_ids = scope.selectedOrderCycles.map (oc) -> oc.id
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
