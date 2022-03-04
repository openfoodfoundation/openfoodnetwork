# frozen_string_literal: true

module SplitCheckoutHelper
  def have_checkout_details
    have_content "Your details"
  end

  def checkout_as_guest
    click_button "Checkout as guest"
  end

  def fill_out_details
    fill_in "First Name", with: "Will"
    fill_in "Last Name", with: "Marshall"
    fill_in "Email", with: "test@test.com"
    fill_in "Phone", with: "0468363090"
  end

  def fill_out_billing_address
    fill_in "order_bill_address_attributes_address1", with: "Rue de la Vie, 77"
    fill_in "order_bill_address_attributes_address2", with: "2nd floor"
    fill_in "order_bill_address_attributes_city", with: "Melbourne"
    fill_in "order_bill_address_attributes_zipcode", with: "3066"
    select "Australia", from: "order_bill_address_attributes_country_id"
    select "Victoria", from: "order_bill_address_attributes_state_id"
  end

  def fill_out_shipping_address
    fill_in "order_ship_address_attributes_address1", with: "Rue de la Vie, 66"
    fill_in "order_ship_address_attributes_address2", with: "3rd floor"
    fill_in "order_ship_address_attributes_city", with: "Perth"
    fill_in "order_ship_address_attributes_zipcode", with: "6603"
    select "Australia", from: "order_ship_address_attributes_country_id"
    select "New South Wales", from: "order_ship_address_attributes_state_id"
  end

  def fill_notes(text)
    fill_in 'Any comments or special instructions?', with: text.to_s
  end

  def proceed_to_payment
    click_button "Next - Payment method"
    expect(page).to have_button("Next - Order summary")
  end

  def expect_to_be_on_first_step
    expect(page).to have_content("1 - Your details")
    expect(page).to have_selector("div.checkout-tab.selected", text: "1 - Your details")
    expect(page).to have_content("2 - Payment method")
    expect(page).to have_content("3 - Order summary")
  end

  def proceed_to_summary
    click_on "Next - Order summary"
    expect(page).to have_button("Complete order")
  end

  def place_order
    click_on "Complete order"
    expect(page).to have_content "Back To Store"
  end
end
