module CheckoutWorkflow
  def have_checkout_details
    have_content "Customer details"
  end

  def toggle_accordion(name)
    find("dd a", text: name).trigger "click"
  end
end
