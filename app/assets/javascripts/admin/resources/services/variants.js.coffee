angular.module("admin.resources").factory 'Variants', ->
  new class Variants
    byID: {}
    pristineByID: {}

    load: (variants) ->
      for variant in variants
        @byID[variant.id] = variant
        @pristineByID[variant.id] = angular.copy(variant)
