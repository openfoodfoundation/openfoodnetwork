Darkswarm.factory 'Variants', ->
  new class Variants
    variants: {}
    register: (variant)->
      @variants[variant.id] ||= @extend variant

    extend: (variant)->
      variant.getPrice = ->
        variant.price * variant.line_item.quantity
      variant.basePricePercentage = Math.round(variant.base_price / variant.price * 100)
      variant
