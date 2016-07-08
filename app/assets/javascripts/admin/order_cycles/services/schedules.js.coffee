angular.module("admin.orderCycles").factory "Schedules", ($q, RequestMonitor, ScheduleResource) ->
  new class Schedules
    byID: {}
    # all: []

    add: (params) ->
      ScheduleResource.create params, (schedule) =>
        @byID[schedule.id] = schedule if schedule.id

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

    linkToOrderCycles: (schedule) ->
      for orderCycle, i in schedule.orderCycles
        orderCycle = OrderCycles.orderCyclesByID[orderCycle.id]
        schedule.orderCycles[i] = orderCycle if orderCycle?
