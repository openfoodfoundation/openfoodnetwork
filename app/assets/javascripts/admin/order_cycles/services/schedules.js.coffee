angular.module("admin.orderCycles").factory "Schedules", ($q, RequestMonitor, ScheduleResource, OrderCycles, Dereferencer) ->
  new class Schedules
    byID: {}
    # all: []

    add: (params) =>
      ScheduleResource.create params, (schedule) =>
        @byID[schedule.id] = schedule if schedule.id?
        Dereferencer.dereference(schedule.order_cycles, OrderCycles.byID)
        orderCycle.schedules.push(schedule) for orderCycle in schedule.order_cycles

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

    # remove: (schedule) ->
    #   params = id: schedule.id
    #   ScheduleResource.destroy params, =>
    #     i = @schedules.indexOf schedule
    #     @schedules.splice i, 1 unless i < 0
    #   , (response) =>
    #     errors = response.data.errors
    #     if errors?
    #       InfoDialog.open 'error', errors[0]
    #     else
    #       InfoDialog.open 'error', "Could not delete schedule: #{schedule.email}"

    index: ->
      request = ScheduleResource.index (data) =>
        @byID[schedule.id] = schedule for schedule in data
        data
        # @all = data
      RequestMonitor.load(request.$promise)
      request
