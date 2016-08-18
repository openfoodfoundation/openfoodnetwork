require 'spec_helper'

feature 'Customers' do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user" do
    let(:user) { create_enterprise_user(enterprise_limit: 10) }
    let(:managed_distributor1) { create(:distributor_enterprise, owner: user) }
    let(:managed_distributor2) { create(:distributor_enterprise, owner: user) }
    let(:unmanaged_distributor) { create(:distributor_enterprise) }

    describe "using the customers index", js: true do
      let!(:customer1) { create(:customer, enterprise: managed_distributor1, code: nil) }
      let!(:customer2) { create(:customer, enterprise: managed_distributor1, code: nil) }
      let!(:customer3) { create(:customer, enterprise: unmanaged_distributor) }
      let!(:customer4) { create(:customer, enterprise: managed_distributor2) }

      before do
        quick_login_as user
        visit admin_customers_path
      end

      it "passes the smoke test" do
        # Prompts for a hub for a list of my managed enterprises
        expect(page).to have_select2 "shop_id", with_options: [managed_distributor1.name,managed_distributor2.name], without_options: [unmanaged_distributor.name]

        select2_select managed_distributor2.name, from: "shop_id"

        # Loads the right customers
        expect(page).to_not have_selector "tr#c_#{customer1.id}"
        expect(page).to_not have_selector "tr#c_#{customer2.id}"
        expect(page).to_not have_selector "tr#c_#{customer3.id}"
        expect(page).to have_selector "tr#c_#{customer4.id}"

        # Changing Shops
        select2_select managed_distributor1.name, from: "shop_id"

        # Loads the right customers
        expect(page).to have_selector "tr#c_#{customer1.id}"
        expect(page).to have_selector "tr#c_#{customer2.id}"
        expect(page).to_not have_selector "tr#c_#{customer3.id}"
        expect(page).to_not have_selector "tr#c_#{customer4.id}"

        # Searching
        fill_in "quick_search", with: customer2.email
        expect(page).to_not have_selector "tr#c_#{customer1.id}"
        expect(page).to have_selector "tr#c_#{customer2.id}"
        fill_in "quick_search", with: ""

        # Toggling columns
        expect(page).to have_selector "th.email"
        expect(page).to have_content customer1.email
        first("div#columns-dropdown", :text => "COLUMNS").click
        first("div#columns-dropdown div.menu div.menu_item", text: "Email").click
        expect(page).to_not have_selector "th.email"
        expect(page).to_not have_content customer1.email

        # Deleting
        create(:order, customer: customer1)
        expect{
          within "tr#c_#{customer1.id}" do
            find("a.delete-customer").trigger('click')
          end
          expect(page).to have_selector "#info-dialog .text", text: "Delete failed: customer has associated orders"
          click_button "OK"
        }.to_not change{Customer.count}

        expect{
          within "tr#c_#{customer2.id}" do
            find("a.delete-customer").click
          end
          expect(page).to_not have_selector "tr#c_#{customer2.id}"
        }.to change{Customer.count}.by(-1)
      end

      it "allows updating of attributes" do
        select2_select managed_distributor1.name, from: "shop_id"

        within "tr#c_#{customer1.id}" do
          fill_in "code", with: "new-customer-code"
          expect(page).to have_css "input[name=code].update-pending"
        end
        within "tr#c_#{customer1.id}" do
          find(:css, "tags-input .tags input").set "awesome\n"
          expect(page).to have_css ".tag_watcher.update-pending"
        end
        click_button "Save Changes"

        # Every says it updated
        expect(page).to have_css "input[name=code].update-success"
        expect(page).to have_css ".tag_watcher.update-success"

        # And it actually did
        expect(customer1.reload.code).to eq "new-customer-code"
        expect(customer1.tag_list).to eq ["awesome"]

        # Clearing attributes
        within "tr#c_#{customer1.id}" do
          fill_in "code", with: ""
          expect(page).to have_css "input[name=code].update-pending"
        end
        within "tr#c_#{customer1.id}" do
          find("tags-input li.tag-item a.remove-button").trigger('click')
          expect(page).to have_css ".tag_watcher.update-pending"
        end
        click_button "Save Changes"

        # Every says it updated
        expect(page).to have_css "input[name=code].update-success"
        expect(page).to have_css ".tag_watcher.update-success"

        # And it actually did
        expect(customer1.reload.code).to be nil
        expect(customer1.tag_list).to eq []
      end

      it "prevents duplicate codes from being saved", retry: 3 do
        select2_select managed_distributor1.name, from: "shop_id"

        within "tr#c_#{customer1.id}" do
          fill_in "code", with: "new-customer-code"
          expect(page).to have_css "input[name=code].update-pending"
        end
        within "tr#c_#{customer2.id}" do
          fill_in "code", with: "new-customer-code"
          expect(page).to have_content "This code is used already."
        end
        click_button "Save Changes"

        within "tr#c_#{customer1.id}" do
          expect(page).to have_css "input[name=code].update-success"
        end

        within "tr#c_#{customer2.id}" do
          expect(page).to have_css "input[name=code].update-error"
        end

        expect(page).to have_content "Oh no! I was unable to save your changes"

        expect(customer1.reload.code).to eq "new-customer-code"
        expect(customer2.reload.code).to be nil
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
          end

          it "creates customers when the email provided is valid" do
            # When an invalid email is used
            expect{
              click_link('New Customer')
              fill_in 'email', with: "not_an_email"
              click_button 'Add Customer'
              expect(page).to have_selector "#new-customer-dialog .error", text: "Please enter a valid email address"
            }.to_not change{Customer.of(managed_distributor1).count}

            # When an existing email is used
            expect{
              fill_in 'email', with: customer1.email
              click_button 'Add Customer'
              expect(page).to have_selector "#new-customer-dialog .error", text: "Email is associated with an existing customer"
            }.to_not change{Customer.of(managed_distributor1).count}

            # When a new valid email is used
            expect{
              fill_in 'email', with: "new@email.com"
              click_button 'Add Customer'
              expect(page).not_to have_selector "#new-customer-dialog"
            }.to change{Customer.of(managed_distributor1).count}.from(2).to(3)
          end
        end
      end
    end
  end
end
