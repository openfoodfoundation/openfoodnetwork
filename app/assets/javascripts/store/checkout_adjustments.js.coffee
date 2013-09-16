$(document).ready ->
  $('#cart_adjustments').hide()

  $('th.cart-adjustment-header').html('<a href="#">Order Adjustments...</a>')
  $('th.cart-adjustment-header a').click ->
    $('#cart_adjustments').toggle()
    $('th.cart-adjustment-header a').html('Order Adjustments')
    false