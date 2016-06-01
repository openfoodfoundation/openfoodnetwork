require 'spec_helper'

feature 'Customers' do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user" do
    let(:user) { create_enterprise_user }
    let(:managed_distributor) { create(:distributor_enterprise, owner: user) }
    let(:unmanaged_distributor) { create(:distributor_enterprise) }

    describe "using the customers index", js: true do
      let!(:customer1) { create(:customer, enterprise: managed_distributor) }
      let!(:customer2) { create(:customer, enterprise: managed_distributor) }
      let!(:customer3) { create(:customer, enterprise: unmanaged_distributor) }

      before do
        quick_login_as user
        visit admin_customers_path
      end

      it "passes the smoke test" do
        # Prompts for a hub for a list of my managed enterprises
        expect(page).to have_select2 "shop_id", with_options: [managed_distributor.name], without_options: [unmanaged_distributor.name]

        select2_select managed_distributor.name, from: "shop_id"

        # Loads the right customers
        expect(page).to have_selector "tr#c_#{customer1.id}"
        expect(page).to have_selector "tr#c_#{customer2.id}"
        expect(page).to_not have_selector "tr#c_#{customer3.id}"

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
      end

      it "allows updating of attributes" do
        select2_select managed_distributor.name, from: "shop_id"

        within "tr#c_#{customer1.id}" do
          fill_in "code", with: "new-customer-code"
          expect(page).to have_css "input#code.update-pending"
        end
        within "tr#c_#{customer1.id}" do
          find(:css, "tags-input .tags input").set "awesome\n"
          expect(page).to have_css ".tag_watcher.update-pending"
        end
        click_button "Save Changes"

        # Every says it updated
        expect(page).to have_css "input#code.update-success"
        expect(page).to have_css ".tag_watcher.update-success"

        # And it actually did
        expect(customer1.reload.code).to eq "new-customer-code"
        expect(customer1.tag_list).to eq ["awesome"]
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
            select2_select managed_distributor.name, from: "shop_id"
          end

          it "creates customers when the email provided is valid" do
            # When an invalid email is used
            expect{
              click_link('New Customer')
              fill_in 'email', with: "not_an_email"
              click_button 'Add Customer'
              expect(page).to have_selector "#new-customer-dialog .error", text: "Please enter a valid email address"
            }.to_not change{Customer.of(managed_distributor).count}

            # When an existing email is used
            expect{
              fill_in 'email', with: customer1.email
              click_button 'Add Customer'
              expect(page).to have_selector "#new-customer-dialog .error", text: "Email is associated with an existing customer"
            }.to_not change{Customer.of(managed_distributor).count}

            # When a new valid email is used
            expect{
              fill_in 'email', with: "new@email.com"
              click_button 'Add Customer'
              expect(page).not_to have_selector "#new-customer-dialog"
            }.to change{Customer.of(managed_distributor).count}.from(2).to(3)
          end
        end
      end
    end
  end
end
