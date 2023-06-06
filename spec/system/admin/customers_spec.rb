# frozen_string_literal: true

require 'system_helper'

describe 'Customers' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  context "as an enterprise user" do
    let(:user) { create(:user, enterprise_limit: 10) }
    let(:managed_distributor1) { create(:distributor_enterprise, owner: user) }
    let(:managed_distributor2) { create(:distributor_enterprise, owner: user) }
    let(:unmanaged_distributor) { create(:distributor_enterprise) }

    describe "using the customers index" do
      let!(:customer1) {
        create(:customer, first_name: 'John', last_name: 'Doe', enterprise: managed_distributor1, 
code: nil, created_manually: true)
      }
      let!(:customer2) {
        create(:customer, enterprise: managed_distributor1, created_manually: true, code: nil)
      }
      let!(:customer3) {
        create(:customer, enterprise: unmanaged_distributor, created_manually: true,)
      }
      let!(:customer4) {
        create(:customer, enterprise: managed_distributor2, created_manually: true,)
      }

      before do
        login_as user
        visit admin_customers_path
      end

      it "passes the smoke test" do
        # Prompts for a hub for a list of my managed enterprises
        expect(page)
          .to have_select2 "shop_id", with_options: [managed_distributor1.name,
            managed_distributor2.name], without_options: [unmanaged_distributor.name]

        select2_select managed_distributor2.name, from: "shop_id"

        # Loads the right customers; positive assertion first, so DOM content is loaded
        expect(page).to have_selector "tr#c_#{customer4.id}"
        expect(page).to have_no_selector "tr#c_#{customer1.id}"
        expect(page).to have_no_selector "tr#c_#{customer2.id}"
        expect(page).to have_no_selector "tr#c_#{customer3.id}"

        # Changing Shops
        select2_select managed_distributor1.name, from: "shop_id"

        # Loads the right customers
        expect(page).to have_selector "tr#c_#{customer1.id}"
        expect(page).to have_selector "tr#c_#{customer2.id}"
        expect(page).to have_no_selector "tr#c_#{customer3.id}"
        expect(page).to have_no_selector "tr#c_#{customer4.id}"

        # Searching
        fill_in "quick_search", with: customer2.email
        expect(page).to have_no_selector "tr#c_#{customer1.id}"
        expect(page).to have_selector "tr#c_#{customer2.id}"
        fill_in "quick_search", with: ""

        # Sorting when the header of a sortable column is clicked
        customer_emails = [customer1.email, customer2.email].sort
        within "#customers thead" do
          click_on "Email"
        end
        expect(page).to have_selector("#customers .customer:nth-child(1) .email",
                                      text: customer_emails[0])
        expect(page).to have_selector("#customers .customer:nth-child(2) .email",
                                      text: customer_emails[1])

        # Then sorting in reverse when the header is clicked again
        within "#customers thead" do
          click_on "Email"
        end
        expect(page).to have_selector("#customers .customer:nth-child(1) .email",
                                      text: customer_emails[1])
        expect(page).to have_selector("#customers .customer:nth-child(2) .email",
                                      text: customer_emails[0])

        # Toggling columns
        expect(page).to have_selector "th.email"
        expect(page).to have_content customer1.email
        toggle_columns "Email"
        expect(page).to have_no_selector "th.email"
        expect(page).to have_no_content customer1.email

        # Deleting
        create(:subscription, customer: customer1)
        expect{
          within "tr#c_#{customer1.id}" do
            accept_alert do
              find("a.delete-customer").click
            end
          end
          expect(page).to have_selector "#info-dialog .text",
                                        text: 'Delete failed: This customer has '\
                                        'active subscriptions. Cancel them first.'
          click_button "OK"
        }.to_not change{ Customer.count }

        expect{
          within "tr#c_#{customer2.id}" do
            accept_alert do
              find("a.delete-customer").click
            end
          end
          expect(page).to have_no_selector "tr#c_#{customer2.id}"
        }.to change{ Customer.count }.by(-1)
      end

      describe "for a shop with multiple customers" do
        let!(:order1) {
          create(:order, total: 0, payment_total: 88, distributor: managed_distributor1, user: nil,
                         state: 'complete', customer: customer1)
        }
        let!(:order2) {
          create(:order, total: 99, payment_total: 0, distributor: managed_distributor1, user: nil,
                         state: 'complete', customer: customer2)
        }
        let!(:order3) {
          create(:order, total: 0,  payment_total: 0, distributor: managed_distributor1, user: nil,
                         state: 'complete', customer: customer4)
        }

        let!(:payment_method) {
          create(:stripe_sca_payment_method, distributors: [managed_distributor1])
        }
        let!(:payment1) {
          create(:payment, :completed, order: order1, payment_method: payment_method,
                                       response_code: 'pi_123', amount: 88.00)
        }

        before do
          customer4.update enterprise: managed_distributor1
        end

        context "with one payment only" do
          it "displays customer balances" do
            select2_select managed_distributor1.name, from: "shop_id"

            within "tr#c_#{customer1.id}" do
              expect(page).to have_content "CREDIT OWED"
              expect(page).to have_content "$88.00"
            end
            within "tr#c_#{customer2.id}" do
              expect(page).to have_content "BALANCE DUE"
              expect(page).to have_content "$-99.00"
            end
            within "tr#c_#{customer4.id}" do
              expect(page).to_not have_content "CREDIT OWED"
              expect(page).to_not have_content "BALANCE DUE"
              expect(page).to have_content "$0.00"
            end
          end
        end

        context "with an additional negative payment (or refund)" do
          let!(:payment2) {
            create(:payment, :completed, order: order1, payment_method: payment_method,
                                         response_code: 'pi_123', amount: -25.00)
          }

          before do
            order1.user = user
            order1.save!
          end

          it "displays an updated customer balance" do
            visit spree.admin_order_payments_path order1
            expect(page).to have_content "$#{payment2.amount}"

            visit admin_customers_path
            select2_select managed_distributor1.name, from: "shop_id"

            within "tr#c_#{customer1.id}" do
              expect(page).to have_content "CREDIT OWED"
              expect(page).to have_content "$63.00"
            end
          end
        end
      end

      it "allows updating of attributes" do
        select2_select managed_distributor1.name, from: "shop_id"

        within "tr#c_#{customer1.id}" do
          expect(find_field('first_name').value).to eq 'John'
          expect(find_field('last_name').value).to eq 'Doe'

          fill_in "code", with: "new-customer-code"
          expect(page).to have_css "input[name=code].update-pending"

          fill_in "first_name", with: "customer abc"
          expect(page).to have_css "input[name=first_name].update-pending"

          find(:css, "tags-input .tags input").set "awesome\n"
          expect(page).to have_css ".tag_watcher.update-pending"
        end
        expect(page).to have_content 'You have unsaved changes'
        click_button "Save Changes"

        # Every says it updated
        expect(page).to have_css "input[name=code].update-success"
        expect(page).to have_css "input[name=first_name].update-success"
        expect(page).to have_css ".tag_watcher.update-success"

        # And it actually did
        expect(customer1.reload.code).to eq "new-customer-code"
        expect(customer1.reload.first_name).to eq "customer abc"
        expect(customer1.tag_list).to eq ["awesome"]

        # Clearing attributes
        within "tr#c_#{customer1.id}" do
          fill_in "code", with: ""
          expect(page).to have_css "input[name=code].update-pending"

          fill_in "first_name", with: ""
          expect(page).to have_css "input[name=first_name].update-pending"

          find("tags-input li.tag-item a.remove-button").click
          expect(page).to have_css ".tag_watcher.update-pending"
        end
        click_button "Save Changes"

        # Every says it updated
        expect(page).to have_css "input[name=code].update-success"
        expect(page).to have_css "input[name=first_name].update-success"
        expect(page).to have_css ".tag_watcher.update-success"

        # And it actually did
        expect(customer1.reload.code).to be nil
        expect(customer1.reload.first_name).to eq ''
        expect(customer1.tag_list).to eq []
      end

      it "prevents duplicate codes from being saved" do
        select2_select managed_distributor1.name, from: "shop_id"

        within "tr#c_#{customer1.id}" do
          fill_in "code", with: "new-customer-code"
          expect(page).to have_css "input[name=code].update-pending"
        end

        click_button "Save Changes"

        within "tr#c_#{customer1.id}" do
          expect(page).to have_css "input[name=code].update-success"
        end

        within "tr#c_#{customer2.id}" do
          fill_in "code", with: "new-customer-code"
          expect(page).to have_content "This code is used already."
        end

        click_button "Save Changes"

        within "tr#c_#{customer2.id}" do
          expect(page).to have_css "input[name=code].update-error"
        end

        expect(page).to have_content "Oh no! I was unable to save your changes"

        expect(customer1.reload.code).to eq "new-customer-code"
        expect(customer2.reload.code).to be nil
      end

      describe 'updating a customer addresses' do
        before do
          select2_select managed_distributor2.name, from: "shop_id"
        end

        it 'updates the existing billing address' do
          expect(page).to have_content 'BILLING ADDRESS'
          first('#bill-address-link').click
          wait_for_modal_fade_in

          expect(page).to have_content 'Edit Billing Address'
          expect(page).to have_select2 'country_id', selected: 'Australia'
          expect(page).to have_select2 'state_id', selected: 'Victoria'

          fill_in 'address1', with: ""
          click_button 'Update Address'

          expect(page).to have_content 'Please input all of the required fields'

          fill_in 'address1', with: "New Address1"
          click_button 'Update Address'

          expect(page).to have_content 'Address updated successfully.'
          expect(page).to have_link 'New Address1'
          expect(customer4.reload.bill_address.address1).to eq 'New Address1'

          first('#bill-address-link').click

          expect(page).to have_content 'Edit Billing Address'
          expect(page).to_not have_content 'Please input all of the required fields'
        end

        it 'creates a new shipping address' do
          expect(page).to have_content 'SHIPPING ADDRESS'

          first('#ship-address-link').click
          wait_for_modal_fade_in
          expect(page).to have_content 'Edit Shipping Address'

          fill_in 'firstname', with: "First"
          fill_in 'lastname', with: "Last"
          fill_in 'address1', with: "New Address1"
          fill_in 'phone', with: "12345678"
          fill_in 'city', with: "Melbourne"
          fill_in 'zipcode', with: "3000"

          select2_select 'Australia', from: 'country_id'
          select2_select 'Victoria', from: 'state_id'
          click_button 'Update Address'

          expect(page).to have_content 'Address updated successfully.'
          expect(page).to have_link 'New Address1'

          ship_address = customer4.reload.ship_address

          expect(ship_address.firstname).to eq 'First'
          expect(ship_address.lastname).to eq 'Last'
          expect(ship_address.address1).to eq 'New Address1'
          expect(ship_address.phone).to eq '12345678'
          expect(ship_address.city).to eq 'Melbourne'
        end

        # Modal animations are defined in:
        # app/assets/javascripts/admin/utils/services/dialog_defaults.js.coffee
        #
        # Without waiting, `fill_in` can fail randomly:
        # https://github.com/teamcapybara/capybara/issues/1890
        def wait_for_modal_fade_in(time = 0.4)
          sleep time
        end
      end

      describe "creating a new customer" do
        context "when no shop has been selected" do
          it "asks the user to select a shop" do
            accept_alert 'Please select a shop first' do
              click_link('New Customer')
            end
          end
        end

        context "when a shop is selected" do
          before do
            select2_select managed_distributor1.name, from: "shop_id"
            customer1.update!(created_manually: false)
          end

          it "creates customers when the email provided is valid" do
            # When an invalid email without domain is used it is checked by a regex, in the UI
            expect{
              click_link('New Customer')
              fill_in 'email', with: "email_with_no_domain@"
              click_button 'Add Customer'
              expect(page).to have_selector "#new-customer-dialog .error",
                                            text: "Please enter a valid email address"
            }.to_not change{ Customer.of(managed_distributor1).count }

            # When an invalid email with domain is used it's checked by "valid_email2" gem #7886
            expect{
              fill_in 'email', with: "invalid_email_with_no_complete_domain@incomplete"
              click_button 'Add Customer'
              expect(page).to have_selector "#new-customer-dialog .error",
                                            text: "Email is invalid"
            }.to_not change{ Customer.of(managed_distributor1).count }

            # When an existing email is used
            expect{
              fill_in 'email', with: customer1.email
              click_button 'Add Customer'
              expect(page).to have_selector "#new-customer-dialog .error",
                                            text: "Email is associated with an existing customer"
            }.to change{ customer1.reload.created_manually }.from(false).to(true)
              .and change { Customer.of(managed_distributor1).count }.by(0)

            # When a new valid email is used
            expect{
              fill_in 'email', with: "new@email.com"
              click_button 'Add Customer'
              expect(page).not_to have_selector "#new-customer-dialog"
            }.to change{ Customer.of(managed_distributor1).count }.from(2).to(3)

            expect(
              Customer.of(managed_distributor1).reorder(:id)
                .last.created_manually 
            ).to be true
          end
        end
      end
    end
  end
end
