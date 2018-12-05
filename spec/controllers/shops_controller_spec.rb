require 'spec_helper'

describe ShopsController, type: :controller do
  render_views

  let!(:distributor) { create(:distributor_enterprise) }
  let!(:invisible_distributor) { create(:distributor_enterprise, visible: false) }

  before do
    allow(Enterprise).to receive_message_chain(:distributors_with_active_order_cycles, :ready_for_checkout) { [distributor] }
  end

  # Exclusion from actual rendered view handled in features/consumer/home
  it "shows JSON for invisible hubs" do
    get :index
    expect(response.body).to have_content(invisible_distributor.name)
  end
end
