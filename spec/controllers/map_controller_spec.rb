require 'spec_helper'

describe MapController do
  it "loads all visible enterprises" do
    Enterprise.should_receive(:visible)
    get :index
  end
end
