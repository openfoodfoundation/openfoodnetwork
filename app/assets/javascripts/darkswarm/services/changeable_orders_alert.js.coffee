angular.module('Darkswarm').factory 'ChangeableOrdersAlert', ($http) ->
  new class ChangeableOrdersAlert
    html: ''
    visible: true

    constructor: ->
      @reload()

    reload: ->
      $http.get('/shop/changeable_orders_alert').then (response) =>
        @html = response.data.trim()

    close: =>
      @visible = false
