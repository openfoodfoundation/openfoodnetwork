$(document).ready ->
  $('#cart_adjustments').hide()

  $('th.cart-adjustment-header').html('<a href="#">Distribution...</a>')
  $('th.cart-adjustment-header a').click ->
    $('#cart_adjustments').toggle()
    $('th.cart-adjustment-header a').html('Distribution')
    false
