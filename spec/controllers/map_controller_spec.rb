require 'spec_helper'

describe MapController do
  it "loads active distributors" do
    active_distributors = double(:distributors)

    Enterprise.stub(:distributors_with_active_order_cycles) { active_distributors }

    get :index

    assigns(:active_distributors).should == active_distributors
  end
end
