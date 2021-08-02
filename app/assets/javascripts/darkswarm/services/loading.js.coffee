angular.module('Darkswarm').factory "Loading", ->
  new class Loading
    message: null
    clear: =>
      @message = null
