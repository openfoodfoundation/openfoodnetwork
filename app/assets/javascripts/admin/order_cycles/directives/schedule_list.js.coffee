angular.module("admin.orderCycles").directive 'scheduleList', (RequestMonitor, Schedules) ->
  restrict: 'E'
  scope:
    orderCycle: '='
  template: "<div><span ng-repeat='schedule in schedules'>{{ schedule.name + ($last ? '' : ', ')}}</span></div>"
  link: (scope, element, attr) ->
    scope.schedules = []

    scope.$watchCollection 'orderCycle.schedule_ids', (newValue, oldValue) ->
      return unless  newValue? && RequestMonitor.loadId > 0 # Request for schedules needs to have been sent
      scope.schedules = []
      RequestMonitor.loadQueue.then ->
        for id in scope.orderCycle.schedule_ids
          schedule = Schedules.byID[id]
          scope.schedules.push schedule if schedule?
