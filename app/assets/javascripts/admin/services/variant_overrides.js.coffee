angular.module("ofn.admin").factory "VariantOverrides", (variantOverrides, Indexer) ->
  new class VariantOverrides
    variantOverrides: {}

    constructor: ->
      @variantOverrides = Indexer.index variantOverrides, 'variant_id'
