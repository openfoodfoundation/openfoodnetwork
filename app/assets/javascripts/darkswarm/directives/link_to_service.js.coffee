angular.module('Darkswarm').directive "linkToService", ->
  restrict: 'E'
  replace: true
  scope: {
    ref: '='
    service: '='
  }
  template: '<a href="{{ref | ext_url: service}}" target="_blank" ng-show="ref"></a>'
