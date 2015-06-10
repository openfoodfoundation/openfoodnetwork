require 'spec_helper'

describe ShopsController do
  render_views
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:invisible_distributor) { create(:distributor_enterprise, visible: false) }

  before do
    Enterprise.stub(:distributors_with_active_order_cycles) { [distributor] }
  end

  # Exclusion from actual rendered view handled in features/consumer/home
  it "shows JSON for invisible hubs" do
    get :index
    response.body.should have_content invisible_distributor.name
  end
end
