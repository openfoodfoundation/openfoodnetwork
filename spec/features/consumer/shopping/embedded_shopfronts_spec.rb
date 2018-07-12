require 'spec_helper'

feature "Using embedded shopfront functionality", js: true do
  include OpenFoodNetwork::EmbeddedPagesHelper
  include AuthenticationWorkflow
  include WebHelper
  include ShopWorkflow
  include CheckoutWorkflow
  include UIComponentHelper

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
      Spree::Config[:embedded_shopfronts_whitelist] = 'test.com'

      allow_any_instance_of(ActionDispatch::Request).to receive(:referer).and_return('https://www.test.com')
      visit "/embedded-shop-preview.html?#{distributor.permalink}"
    end

    after do
      Spree::Config[:enable_embedded_shopfronts] = false
    end

    it "displays modified shopfront layout" do
      on_embedded_page do
        within 'nav.top-bar' do
          expect(page).to have_selector 'ul.left', visible: false
          expect(page).to have_selector 'ul.center', visible: false
        end

        expect(page).to have_content "My Embedded Hub"
        expect(page).to have_content "Framed Apples"
      end
    end

    it "allows shopping and checkout" do
      on_embedded_page do
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

        within "#billing" do
          fill_in "Address", with: "123 Street"
          select "Australia", from: "Country"
          select "Victoria", from: "State"
          fill_in "City", with: "Melbourne"
          fill_in "Postcode", with: "3066"
        end

        within "#shipping" do
          find('input[type="radio"]').click
        end

        within "#payment" do
          find('input[type="radio"]').click
        end

        place_order

        expect(page).to have_content "Your order has been processed successfully"
      end
    end

    it "redirects to embedded hub on logout when embedded" do
      on_embedded_page do
        wait_for_shop_loaded
        find('ul.right li#login-link a').click
        login_with_modal

        wait_for_shop_loaded
        wait_until { page.find('ul.right li.user-menu.has-dropdown').value.present? }
        logout_via_navigation

        expect(page).to have_text 'My Embedded Hub'
      end
    end
  end

  private

  # When you have pending changes and try to navigate away from a page, it asks you "Are you sure?".
  # When we click the "Update" button to save changes, we need to wait
  #   until it is actually saved and "loading" disappears before doing anything else.
  def wait_for_shop_loaded
    page.has_no_content? "Loading"
    page.has_no_css? "input[value='Updating cart...']"
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
    first('ul.right li.user-menu a').click
    find('ul.right ul.dropdown li a[title="Logout"]').click
  end
end
