require 'spec_helper'

feature "Using embedded shopfront functionality", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include CheckoutWorkflow
  include UIComponentHelper

  Capybara.server_port = 9999

  describe "using iframes" do
    let(:distributor) { create(:distributor_enterprise, name: 'My Embedded Hub', permalink: 'test_enterprise', with_payment_and_shipping: true) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:oc1) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now) }
    let(:product) { create(:simple_product, name: 'Framed Apples', supplier: supplier) }
    let(:variant) { create(:variant, product: product, price: 19.99) }
    let(:exchange) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }
    let(:user) { create(:user) }

    before do
      add_variant_to_order_cycle(exchange, variant)

      Spree::Config[:enable_embedded_shopfronts] = true
      Spree::Config[:embedded_shopfronts_whitelist] = 'localhost'

      page.driver.browser.js_errors = false
      Capybara.current_session.driver.visit('spec/support/views/iframe_test.html')
    end

    after do
      Spree::Config[:enable_embedded_shopfronts] = false
    end

    it "displays modified shopfront layout" do
      expect(page).to have_selector 'iframe#test_iframe'

      within_frame 'test_iframe' do
        within 'nav.top-bar' do
          expect(page).to have_selector 'ul.left', visible: false
          expect(page).to have_selector 'ul.center', visible: false
        end

        expect(page).to have_content "My Embedded Hub"
        expect(page).to have_content "Framed Apples"
      end
    end

    it "allows shopping and checkout" do
      within_frame 'test_iframe' do
        fill_in "variants[#{variant.id}]", with: 1
        wait_until_enabled 'input.add_to_cart'

        first("input.add_to_cart:not([disabled='disabled'])").click

        expect(page).to have_text 'Your shopping cart'
        find('a#checkout-link').click

        expect(page).to have_text 'Checkout now'

        click_button 'Login'
        login_with_modal

        expect(page).to have_text 'Payment'

        within "#details" do
          fill_in "First Name", with: "Some"
          fill_in "Last Name", with: "One"
          fill_in "Email", with: "test@example.com"
          fill_in "Phone", with: "0456789012"
        end

        toggle_billing
        within "#billing" do
          fill_in "Address", with: "123 Street"
          select "Australia", from: "Country"
          select "Victoria", from: "State"
          fill_in "City", with: "Melbourne"
          fill_in "Postcode", with: "3066"
        end

        toggle_shipping
        within "#shipping" do
          find('input[type="radio"]').trigger 'click'
        end

        toggle_payment
        within "#payment" do
          find('input[type="radio"]').trigger 'click'
        end

        place_order

        expect(page).to have_content "Your order has been processed successfully"
      end
    end

    it "redirects to embedded hub on logout when embedded" do
      within_frame 'test_iframe' do

        find('ul.right li#login-link a').click
        login_with_modal

        wait_until { page.find('ul.right li.has-dropdown').value.present? }
        logout_via_navigation

        expect(page).to have_text 'My Embedded Hub'
      end
    end
  end

  def login_with_modal
    expect(page).to have_selector 'div.login-modal', visible: true

    within 'div.login-modal' do
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      find('input[type="submit"]').click
    end
  end

  def logout_via_navigation
    first('ul.right li.has-dropdown a').click
    find('ul.right ul.dropdown li a[title="Logout"]').click
  end
end
