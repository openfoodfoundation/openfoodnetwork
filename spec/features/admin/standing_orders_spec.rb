require 'spec_helper'

feature 'Standing Orders' do
  include AuthenticationWorkflow
  include WebHelper

  context "as an enterprise user", js: true do
    let!(:user) { create_enterprise_user(enterprise_limit: 10) }
    let!(:enterprise) { create(:distributor_enterprise, owner: user) }
    let!(:customer) { create(:customer, enterprise: enterprise) }
    let!(:schedule) { create(:schedule, order_cycles: [create(:simple_order_cycle, coordinator: enterprise)]) }
    let!(:payment_method) { create(:payment_method, distributors: [enterprise]) }
    let!(:shipping_method) { create(:shipping_method, distributors: [enterprise]) }

    before { quick_login_as user }

    it "I can create a new standing order" do
      visit new_admin_standing_order_path(enterprise_id: enterprise.permalink)

      select2_select customer.email, from: 'customer_id'
      select2_select schedule.name, from: 'schedule_id'
      select2_select payment_method.name, from: 'payment_method_id'
      select2_select shipping_method.name, from: 'shipping_method_id'

      # No date filled out, so error returned
      expect{
        click_button('Save')
        expect(page).to have_content 'Oh no! I was unable to save your changes.'
      }.to_not change(StandingOrder, :count)

      expect(page).to have_content 'Begins at can\'t be blank'
      fill_in 'begins_at', with: Date.today.strftime('%F')

      # Date filled out, so submit should be successful
      expect{
        click_button('Save')
        expect(page).to have_content 'Saved'
      }.to change(StandingOrder, :count).by(1)

      standing_order = StandingOrder.last
      expect(standing_order.customer).to eq customer
      expect(standing_order.schedule).to eq schedule
      expect(standing_order.payment_method).to eq payment_method
      expect(standing_order.shipping_method).to eq shipping_method
    end
  end
end
