require 'spec_helper'

describe HomeController do
  render_views
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:invisible_distributor) { create(:distributor_enterprise, visible: false) }

  before do
    Enterprise.stub(:distributors_with_active_order_cycles).and_return [distributor]
    Enterprise.stub(:visible).and_return [distributor]
  end

  it "sets active distributors" do
    get :index
    assigns[:active_distributors].should == [distributor]
  end

  it "loads visible enterprises" do
    get :index
    assigns[:enterprises].should == [distributor]
  end

  it "does not show invisible hubs" do
    get :index
    response.body.should_not have_content invisible_distributor.name
  end
  
  # This is done inside the json/hubs RABL template
  it "gets the next order cycle for each hub" do
    OrderCycle.should_receive(:first_closing_for).with(distributor)
    get :index
  end
end

