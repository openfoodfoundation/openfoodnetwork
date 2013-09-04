$(document).ready ->
  $("#order_order_cycle_id").change -> $("#order_cycle_select").submit()
  $("#reset_order_cycle").click -> return false unless confirm "Performing this action will clear your cart."


