# frozen_string_literal: true

RSpec.describe "spree/admin/orders/_filters.html.haml" do
  helper Spree::Admin::NavigationHelper
  helper Spree::Admin::BaseHelper

  before do
    user = create(:user)
    allow(view).to receive_messages spree_current_user: user
    allow(Spree::ShippingMethod).to receive(:managed_by).and_return(Spree::ShippingMethod.none)
    allow(Enterprise).to receive(:is_distributor).and_return(
      double(managed_by: Enterprise.none)
    )
    allow(OrderCycle).to receive(:managed_by).and_return(
      OrderCycle.none
    )
  end

  it "has a label correctly associated with the date range input" do
    render

    # The label's 'for' attribute must match the input's 'id'
    expect(rendered).to have_css('label[for="orders_date_range"]')
    expect(rendered).to have_css('input[id="orders_date_range"]')
  end

  it "has a label correctly associated with the status select" do
    render

    expect(rendered).to have_css('label[for="q_state_eq"]')
    expect(rendered).to have_css('select[id="q_state_eq"]')
  end

  it "has a label correctly associated with the shipping method select" do
    render

    expect(rendered).to have_css('label[for="shipping_method_id"]')
    expect(rendered).to have_css('select[id="shipping_method_id"]')
  end

  it "has a label correctly associated with the distributor select" do
    render

    expect(rendered).to have_css('label[for="q_distributor_id_in"]')
    expect(rendered).to have_css('select[id="q_distributor_id_in"]')
  end

  it "has a label correctly associated with the order cycle select" do
    render

    expect(rendered).to have_css('label[for="q_order_cycle_id_in"]')
    expect(rendered).to have_css('select[id="q_order_cycle_id_in"]')
  end
end
