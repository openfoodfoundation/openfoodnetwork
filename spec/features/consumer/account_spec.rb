require 'spec_helper'

feature %q{
    As a consumer
    I want to view my order history with each hub
    and view any outstanding balance.
}, js: true do
  include UIComponentHelper
  include AuthenticationWorkflow
  let!(:user) { create(:user)}
  let!(:distributor1) { create(:distributor_enterprise) }
  let!(:distributor2) { create(:distributor_enterprise) }
  let!(:distributor_without_orders) { create(:distributor_enterprise) }
  let!(:d1o1) { create(:completed_order_with_totals, distributor: distributor1, user_id: user.id, total: 10000)}
  let!(:d1o2) { create(:completed_order_with_totals, distributor: distributor1, user_id: user.id, total: 5000)}
  let!(:d2o1) { create(:completed_order_with_totals, distributor: distributor2, user_id: user.id)}

  let!(:d1o1p) { create(:payment, order: d1o1)}

  before do
    login_as user
    visit "/account"
  end

  it "shows all hubs that have been ordered from" do
    expect(page).to have_content distributor1.name
    expect(page).to have_content distributor2.name
    expect(page).not_to have_content distributor_without_orders.name
  end

  it "reveals table of orders for distributors when clicked" do
    expand_active_table_node distributor1.name
    expect(page).to have_content d1o1.id
    expand_active_table_node distributor2.name
    expect(page).not_to have_content d1o1.id
  end

end
