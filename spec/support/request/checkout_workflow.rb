module CheckoutWorkflow
  def have_checkout_details
    have_content "Your details"
  end

  def checkout_as_guest
    click_button "Checkout as guest"
  end

  def place_order
    find("button", text: "Place order now").click
  end

  def toggle_accordion(id)
    find("##{id} dd a").click
  end

  def toggle_details
    toggle_accordion :details
  end
end
