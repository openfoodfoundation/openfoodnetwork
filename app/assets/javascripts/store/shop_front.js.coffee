$(document).ready ->
  $("#order_order_cycle_id").change -> $("#order_cycle_select").submit()
  $("#reset_order_cycle").click -> return false unless confirm "Changing your collection date will clear your cart."
  $(".shop-distributor.empties-cart").click -> return false unless confirm "Changing your location will clear your cart."
