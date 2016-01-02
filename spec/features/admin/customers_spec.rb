require 'spec_helper'

feature 'Customers' do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user" do
    let(:user) { create_enterprise_user }
    let(:managed_distributor) { create(:distributor_enterprise, owner: user) }
    let(:unmanaged_distributor) { create(:distributor_enterprise) }

    describe "using the customers index" do
      let!(:customer1) { create(:customer, enterprise: managed_distributor) }
      let!(:customer2) { create(:customer, enterprise: managed_distributor) }
      let!(:customer3) { create(:customer, enterprise: unmanaged_distributor) }

      before do
        quick_login_as user
        visit admin_customers_path
      end

      it "passes the smoke test", js: true do
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
        first("div#columns_dropdown", text: "COLUMNS").click
        first("div#columns_dropdown div.menu div.menu_item", text: "Email").click
        expect(page).to_not have_selector "th.email"
        expect(page).to_not have_content customer1.email
      end

      it "allows updating of attributes", js: true do
        select2_select managed_distributor.name, from: "shop_id"

        within "tr#c_#{customer1.id}" do
          fill_in "code", with: "new-customer-code"
          expect(page).to have_css "input#code.update-pending"
        end
        within "tr#c_#{customer1.id}" do
          find(:css, "tags-input .tags input").set "awesome\n"
          expect(page).to have_css ".tag_watcher.update-pending"
        end
        click_button "Update"

        # Every says it updated
        expect(page).to have_css "input#code.update-success"
        expect(page).to have_css ".tag_watcher.update-success"

        # And it actually did
        expect(customer1.reload.code).to eq "new-customer-code"
        expect(customer1.tag_list).to eq ["awesome"]
      end
    end
  end
end
