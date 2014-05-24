angular.module("ofn.admin").factory 'Enterprises', (my_enterprises, all_enterprises) ->
  new class Enterprises
    constructor: ->
      @my_enterprises = my_enterprises
      @all_enterprises = all_enterprises
