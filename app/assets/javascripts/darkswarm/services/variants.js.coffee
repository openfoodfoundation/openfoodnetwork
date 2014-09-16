Darkswarm.factory 'Variants', ->
  new class Variants
    variants: {}
    register: (variant)->
      @variants[variant.id] ||= @extend variant

    extend: (variant)->
      variant.totalPrice = ->
        variant.price_with_fees * variant.line_item.quantity
      variant.basePricePercentage = Math.round(variant.price / variant.price_with_fees * 100)
      variant
