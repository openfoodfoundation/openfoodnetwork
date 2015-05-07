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
      let!(:customer2) { create(:customer, enterprise: unmanaged_distributor) }

      before do
        quick_login_as user
        visit admin_customers_path
      end

      it "lists my customers", js: true do
        # Prompts for a hub
        expect(page).to have_select2 "shop_id", with_options: [managed_distributor.name], without_options: [unmanaged_distributor.name]

        select2_select managed_distributor.name, from: "shop_id"
        click_button "Go"

        expect(page).to have_content customer1.email
        expect(page).to have_content customer1.code
        expect(page).to_not have_content customer2.email
        expect(page).to_not have_content customer2.code
      end
    end
  end
end
