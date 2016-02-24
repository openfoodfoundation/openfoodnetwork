angular.module("admin.indexUtils").directive "ignoreDirty", ->
  restrict: 'A'
  require: 'ngModel'
  link: (scope, element, attrs, ngModel) ->
    #TODO: This is broken, requires AngularJS > 1.3
    ngModel.$setDirty = angular.noop
