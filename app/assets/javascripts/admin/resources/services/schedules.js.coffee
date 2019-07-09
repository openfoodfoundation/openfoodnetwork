angular.module("admin.resources").factory "Schedules", ($q, $injector, RequestMonitor, ScheduleResource, OrderCycles, Dereferencer, StatusMessage) ->
  new class Schedules
    all: []
    byID: {}

    constructor: ->
      if $injector.has('schedules')
        @load($injector.get('schedules'))

    load: (schedules) ->
      for schedule in schedules
        @all.push schedule
        @byID[schedule.id] = schedule

    add: (params) =>
      ScheduleResource.create params, (schedule) =>
        @byID[schedule.id] = schedule if schedule.id?
        Dereferencer.dereference(schedule.order_cycles, OrderCycles.byID)
        orderCycle.schedules.push(schedule) for orderCycle in schedule.order_cycles
        StatusMessage.display 'success', "#{t('js.admin.order_cycles.schedules.created_schedule')}: '#{schedule.name}'"

    update: (params) =>
      ScheduleResource.update params, (schedule) =>
        if schedule.id?
          Dereferencer.dereference(schedule.order_cycles, OrderCycles.byID)
          for orderCycle in @byID[schedule.id].order_cycles when orderCycle.id not in schedule.order_cycle_ids
            if orderCycle.schedules # Only if we need to update the schedules
              orderCycle.schedules.splice(i, 1) for s, i in orderCycle.schedules by -1 when s.id == schedule.id
          for orderCycle in schedule.order_cycles when orderCycle.id not in @byID[schedule.id].order_cycle_ids
            orderCycle.schedules.push(@byID[schedule.id])
          angular.extend(@byID[schedule.id], schedule)
          StatusMessage.display 'success', "#{t('js.admin.order_cycles.schedules.updated_schedule')}: '#{schedule.name}'"

    remove: (schedule) ->
      params = id: schedule.id
      ScheduleResource.destroy params, =>
        for orderCycle in @byID[schedule.id].order_cycles
          if orderCycle.schedules # Only if we need to update the schedules
            orderCycle.schedules.splice(i, 1) for s, i in orderCycle.schedules by -1 when s.id == schedule.id
        delete @byID[schedule.id]
        StatusMessage.display 'success', "#{t('js.admin.order_cycles.schedules.deleted_schedule')}: '#{schedule.name}'"

    index: (params) ->
      request = ScheduleResource.index params, (data) => @load(data)
      RequestMonitor.load(request.$promise)
      request
