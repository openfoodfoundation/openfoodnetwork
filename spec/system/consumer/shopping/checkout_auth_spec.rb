# frozen_string_literal: true

require 'system_helper'

describe "As a consumer I want to check out my cart" do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include CheckoutRequestsHelper
  include UIComponentHelper

  describe "checking out" do
    let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
    let(:supplier) { create(:supplier_enterprise) }
    let!(:order_cycle) {
      create(:simple_order_cycle, distributors: [distributor],
                                  coordinator: create(:distributor_enterprise), variants: [product.variants.first])
    }
    let(:product) { create(:simple_product, supplier: supplier) }
    let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }
    let(:address) { create(:address, firstname: "Foo", lastname: "Bar") }
    let(:user) { create(:user, bill_address: address, ship_address: address) }

    after { Warden.test_reset! }

    before do
      set_order order
      add_product_to_cart order, product
    end

    shared_examples "with different checkout types" do |checkout_type|
      context "on #{checkout_type}" do
        it "does not render the login form when logged in" do
          login_as user
          visit checkout_path
          within "section[role='main']" do
            expect(page).to have_no_content "Login"
            expect(page).to have_checkout_details
          end
        end

        it "renders the login buttons when logged out" do
          visit checkout_path
          within "section[role='main']" do
            expect(page).to have_content "Login"
            click_button "Login"
          end
          expect(page).to have_login_modal
        end

        describe "logging in" do
          before do
            visit checkout_path
            within("section[role='main']") { click_button "Login" }
            expect(page).to have_login_modal
            fill_in "Email", with: user.email
            fill_in "Password", with: user.password
            within(".login-modal") { click_button 'Login' }
          end

          context "and populating user details on (#{checkout_type})", if: checkout_type.eql?("legacy_checkout") do
            it "toggles the Details section" do
              expect(page).to have_content "Your details"
              page.find(:css, "i.ofn-i_052-point-down").click
            end
          end

          context "and populating user details on (#{checkout_type})", if: checkout_type.eql?("split_checkout") do
            it "should allow proceeding to the next step" do
              expect(page).to have_content("Logged in successfully")
              click_button "Next - Payment method"
              expect(page).to have_button("Next - Order summary")
            end
          end
        end
      end
    end

    describe "shared examples" do
      context "legacy checkout" do
        it_behaves_like "with different checkout types", "legacy_checkout"
      end

      context "split checkout" do
        before do
          Flipper.enable(:split_checkout)
        end
        include_examples "with different checkout types", "split_checkout"
      end
    end

    context "using the guest checkout" do
      it "allows user to checkout as guest" do
        visit checkout_path
        checkout_as_guest
        expect(page).to have_checkout_details
      end

      it "asks the user to log in if they are using a registered email" do
        visit checkout_path
        checkout_as_guest

        fill_in 'First Name', with: 'Not'
        fill_in 'Last Name', with: 'Guest'
        fill_in 'Email', with: user.email
        fill_in 'Phone', with: '098712736'

        within '#details' do
          click_button 'Next'
        end

        expect(page).to have_selector 'div.login-modal'
        expect(page).to have_content 'This email address is already registered. Please log in to continue, or go back and use another email address.'
      end
    end
  end
end
