# frozen_string_literal: true

module SplitCheckoutHelper
  def have_checkout_details
    have_content "Your details"
  end

  def checkout_as_guest
    click_button "Checkout as guest"
  end

  def place_order
    find("button", text: "Complete order").click
  end

  def fill_out_details
    # Section: Your Details
    within(:xpath, './/div[@class="checkout-substep"][1]') do
      fill_in "First Name", with: "Will"
      fill_in "Last Name", with: "Marshall"
      fill_in "Email", with: "test@test.com"
      fill_in "Phone", with: "0468363090"
    end
  end

  def fill_out_billing_address
    # Section: Your Billing Address
    within(:xpath, './/div[@class="checkout-substep"][2]') do
      fill_in "Address", with: "Rue de la Vie, 77"
      fill_in "City", with: "Melbourne"
      fill_in "Postcode", with: "3066"
      select "Australia", from: "Country"
      select "Victoria", from: "State"
    end
  end

  def fill_out_shipping_address
    # Section: Delivery Address
    within(:xpath, './/div[@class="checkout-substep"][3]') do
      fill_in "Address", with: "Rue de la Vie, 66"
      fill_in "City", with: "Perth"
      fill_in "Postcode", with: "2899"
      select "Australia", from: "Country"
      select "New South Wales", from: "State"
    end
  end

  def fill_notes(text)
    fill_in 'Any comments or special instructions?', with: text.to_s
  end

  def proceed_to_payment
    click_button "Next - Payment method"
    expect(page).to have_current_path("/checkout/payment")
  end
end
