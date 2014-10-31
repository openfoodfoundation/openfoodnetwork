require 'spec_helper'

describe ProducersController do
  let!(:distributor) { create(:distributor_enterprise) }

  before do
    Enterprise.stub_chain(:distributors_with_active_order_cycles, :ready_for_checkout).
      and_return([distributor])
    Enterprise.stub(:all).and_return([distributor])
  end

  it "sets active distributors" do
    get :index
    assigns[:active_distributors].should == [distributor]
  end
end
