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
  $('.cart_adjustment').hide()

  $('td.cart-adjustments a').click ->
    $('.cart_adjustment').toggle()
    $(this).html(t('item_handling_fees'))
    false
