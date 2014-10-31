require 'spec_helper'

describe MapController do
  it "loads active distributors" do
    active_distributors = double(:distributors)

    Enterprise.stub_chain(:distributors_with_active_order_cycles, :ready_for_checkout).
      and_return(active_distributors)

    get :index

    assigns(:active_distributors).should == active_distributors
  end
end
