require 'spec_helper'

describe HomeController do
  render_views
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:invisible_distributor) { create(:distributor_enterprise, visible: false) }

  before do
    Enterprise.stub_chain(:distributors_with_active_order_cycles, :ready_for_checkout).
      and_return [distributor]
  end

  it "sets active distributors" do
    get :index
    assigns[:active_distributors].should == [distributor]
  end

  # Exclusion from actual rendered view handled in features/consumer/home
  it "shows JSON for invisible hubs" do
    get :index
    response.body.should have_content invisible_distributor.name
  end
  
  # This is done inside the json/hubs Serializer
  it "gets the next order cycle for each hub" do
    OrderCycle.should_receive(:first_closing_for).twice
    get :index
  end
end

