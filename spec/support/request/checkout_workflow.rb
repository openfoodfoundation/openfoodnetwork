module CheckoutWorkflow
  def have_checkout_details
    have_content "Customer details"
  end

  def toggle_accordion(id)
    find("##{id} dd > a").click
  end

  def toggle_details
    toggle_accordion :details
  end
  def toggle_billing
    toggle_accordion :billing
  end
  def toggle_shipping
    toggle_accordion :shipping
  end
  def toggle_payment
    toggle_accordion :payment
  end
end
