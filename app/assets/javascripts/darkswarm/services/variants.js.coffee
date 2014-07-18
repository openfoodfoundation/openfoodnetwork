Darkswarm.factory 'Variants', ->
  new class Variants
    variants: {}
    register: (variant)->
      @variants[variant.id] ||= variant
