require 'spec_helper'

describe MapController do
  it "loads all visible enterprises" do
    Enterprise.should_receive(:visible)
    get :index
  end

  it "loads active distributors" do
    Enterprise.should_receive(:distributors_with_active_order_cycles)
    get :index
  end
end
