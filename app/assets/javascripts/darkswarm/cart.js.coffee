$ ->
  if ($ 'form#update-cart').is('*')
    ($ 'form#update-cart a.delete').show().one 'click', ->
      ($ this).parents('.line-item').first().find('input.line_item_quantity').val 0
      ($ this).parents('form').first().submit()
      false

  ($ 'form#update-cart').submit ->
    ($ 'form#update-cart #update-button').attr('disabled', true)


# Temporarily handles the cart showing stuff
$(document).ready ->
  $('#cart_adjustments').hide()

  $('th.cart-adjustment-header').html('<a href="#">Distribution...</a>')
  $('th.cart-adjustment-header a').click ->
    $('#cart_adjustments').toggle()
    $('th.cart-adjustment-header a').html('Distribution')
    false
