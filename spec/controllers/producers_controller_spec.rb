require 'spec_helper'

describe ProducersController do
  it "gets all active producers" do
    Enterprise.stub_chain(:active)
    get :index
  end
end
