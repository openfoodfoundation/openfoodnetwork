Darkswarm.factory 'Enterprises', (enterprises)->
  new class Enterprises
    constructor: ->
      @enterprises = enterprises
      @dereference()
